//
//  HikeDataService.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

final class HikeDataService {
	static let shared = HikeDataService()
	private let db = Firestore.firestore()
	
	private init() {}
	
	// MARK: - 1. Upload Hike to Firestore
	func uploadHike(_ record: HikeRecord) async throws {
		guard let currentUid = Auth.auth().currentUser?.uid else {
			throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "No authenticated user."])
		}
		
		let batch = db.batch()
		
		// Target: users/{uid}/hikes/{hikeId}
		let hikeDocRef = db.collection("users")
			.document(currentUid)
			.collection("hikes")
			.document(record.id)
		
		// Flatten nested [[Double]] into an Array of GeoPoint objects (Firestore-compatible)
		let geoPoints: [GeoPoint] = record.breadcrumbCoordinates.compactMap { pair in
			guard pair.count >= 2 else { return nil }
			return GeoPoint(latitude: pair[0], longitude: pair[1])
		}
		
		var data: [String: Any] = [
			"id": record.id,
			"userId": currentUid,
			"trailName": record.trailName,
			"distanceMeters": record.distanceMeters,
			"durationSeconds": record.durationSeconds,
			"elevationGainMeters": record.elevationGainMeters,
			"stepCount": record.stepCount,
			"date": Timestamp(date: record.date),
			"breadcrumbCoordinates": geoPoints
		]
		
		if let trailId = record.trailId { data["trailId"] = trailId }
		if let pace = record.averagePaceSecondsPerKm { data["averagePaceSecondsPerKm"] = pace }
		
		batch.setData(data, forDocument: hikeDocRef, merge: true)
		
		// Atomically increment aggregate stats on user root document
		let userDocRef = db.collection("users").document(currentUid)
		batch.setData([
			"totalDistanceMeters": FieldValue.increment(record.distanceMeters),
			"totalHikesCompleted": FieldValue.increment(Int64(1)),
			"totalElevationGainMeters": FieldValue.increment(record.elevationGainMeters),
			"lastActiveDate": FieldValue.serverTimestamp()
		], forDocument: userDocRef, merge: true)
		
		try await batch.commit()
	}
	
	// MARK: - 2. Fetch All Hikes from Firestore
	func fetchUserHikes() async throws -> [HikeRecord] {
		guard let currentUid = Auth.auth().currentUser?.uid else { return [] }
		
		let snapshot = try await db.collection("users")
			.document(currentUid)
			.collection("hikes")
			.order(by: "date", descending: true)
			.getDocuments()
		
		return snapshot.documents.compactMap { doc -> HikeRecord? in
			let d = doc.data()
			guard let name = d["trailName"] as? String,
				  let dist = d["distanceMeters"] as? Double,
				  let dur = d["durationSeconds"] as? Int,
				  let elev = d["elevationGainMeters"] as? Double,
				  let steps = d["stepCount"] as? Int,
				  let ts = d["date"] as? Timestamp else {
				return nil
			}
			
			// Reconstruct [[Double]] from either [GeoPoint] or legacy formats
			var rawCoords: [[Double]] = []
			if let geoPoints = d["breadcrumbCoordinates"] as? [GeoPoint] {
				rawCoords = geoPoints.map { [$0.latitude, $0.longitude] }
			} else if let dicts = d["breadcrumbCoordinates"] as? [[String: Double]] {
				rawCoords = dicts.compactMap {
					guard let lat = $0["lat"], let lon = $0["lon"] else { return nil }
					return [lat, lon]
				}
			}
			
			return HikeRecord(
				id: doc.documentID,
				userId: currentUid,
				trailId: d["trailId"] as? String,
				trailName: name,
				distanceMeters: dist,
				durationSeconds: dur,
				elevationGainMeters: elev,
				stepCount: steps,
				averagePaceSecondsPerKm: d["averagePaceSecondsPerKm"] as? Double,
				date: ts.dateValue(),
				breadcrumbCoordinates: rawCoords,
				isSyncedToCloud: true
			)
		}
	}
	
	// MARK: - 3. Delete Hike from Firestore
	func deleteHike(id: String) async throws {
		guard let currentUid = Auth.auth().currentUser?.uid else { return }
		
		try await db.collection("users")
			.document(currentUid)
			.collection("hikes")
			.document(id)
			.delete()
	}
}
