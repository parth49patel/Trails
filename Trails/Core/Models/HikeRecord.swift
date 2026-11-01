//
//  HikeRecord.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import SwiftData
import CoreLocation

/// Persistent record representing a completed hike saved to local SwiftData storage.
@Model
final class HikeRecord {
	
	// MARK: - Identifiers & Metadata
	@Attribute(.unique) var id: String
	var userId: String
	var trailId: String?
	var trailName: String
	var date: Date
	
	// MARK: - Recorded Geographic Anchors
	var startLatitude: Double?
	var startLongitude: Double?
	var finishLatitude: Double?
	var finishLongitude: Double?
	
	// MARK: - Core 4 Metrics
	var distanceMeters: Double
	var durationSeconds: Int
	var stepCount: Int
	var waypointsData: Data?
	
	// MARK: - Initializer
	init(
		id: String = UUID().uuidString,
		userId: String = "local_user",
		trailId: String? = nil,
		trailName: String,
		distanceMeters: Double,
		durationSeconds: Int,
		stepCount: Int,
		date: Date = Date(),
		startLatitude: Double? = nil,
		startLongitude: Double? = nil,
		finishLatitude: Double? = nil,
		finishLongitude: Double? = nil,
		waypoints: [WaypointMarker] = []
	) {
		self.id = id
		self.userId = userId
		self.trailId = trailId
		self.trailName = trailName
		self.distanceMeters = distanceMeters
		self.durationSeconds = durationSeconds
		self.stepCount = stepCount
		self.date = date
		self.startLatitude = startLatitude
		self.startLongitude = startLongitude
		self.finishLatitude = finishLatitude
		self.finishLongitude = finishLongitude
		self.waypointsData = try? JSONEncoder().encode(waypoints)
	}
	
	// MARK: - Computed Properties
	var startCoordinate: CLLocationCoordinate2D? {
		guard let lat = startLatitude, let lon = startLongitude else { return nil }
		return CLLocationCoordinate2D(latitude: lat, longitude: lon)
	}
	
	var finishCoordinate: CLLocationCoordinate2D? {
		guard let lat = finishLatitude, let lon = finishLongitude else { return nil }
		return CLLocationCoordinate2D(latitude: lat, longitude: lon)
	}
	
	var waypoints: [WaypointMarker] {
		get {
			guard let data = waypointsData else { return [] }
			return (try? JSONDecoder().decode([WaypointMarker].self, from: data)) ?? []
		}
		set {
			waypointsData = try? JSONEncoder().encode(newValue)
		}
	}
	
	var distanceKm: Double {
		distanceMeters / 1000.0
	}
}
