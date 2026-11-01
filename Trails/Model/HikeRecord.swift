//
//  HikeRecord.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class HikeRecord {
	@Attribute(.unique) var id: String
	var userId: String
	var trailId: String?
	var trailName: String
	var distanceMeters: Double
	var durationSeconds: Int
	var elevationGainMeters: Double
	var stepCount: Int
	var averagePaceSecondsPerKm: Double?
	var date: Date
	
	// Serialized coordinates stored as [[latitude, longitude]]
	var breadcrumbCoordinates: [[Double]]
	
	// Serialized WaypointMarker array
	var waypointsData: Data?
	var isSyncedToCloud: Bool

	init(
		id: String = UUID().uuidString,
		userId: String = "local_user",
		trailId: String? = nil,
		trailName: String,
		distanceMeters: Double,
		durationSeconds: Int,
		elevationGainMeters: Double,
		stepCount: Int,
		averagePaceSecondsPerKm: Double? = nil,
		date: Date = Date(),
		breadcrumbCoordinates: [[Double]] = [],
		waypoints: [WaypointMarker] = [],
		isSyncedToCloud: Bool = false
	) {
		self.id = id
		self.userId = userId
		self.trailId = trailId
		self.trailName = trailName
		self.distanceMeters = distanceMeters
		self.durationSeconds = durationSeconds
		self.elevationGainMeters = elevationGainMeters
		self.stepCount = stepCount
		self.averagePaceSecondsPerKm = averagePaceSecondsPerKm
		self.date = date
		self.breadcrumbCoordinates = breadcrumbCoordinates
		self.isSyncedToCloud = isSyncedToCloud
		self.waypointsData = try? JSONEncoder().encode(waypoints)
	}
	
	// Computed property that exposes [WaypointMarker] to your views
	var waypoints: [WaypointMarker] {
		get {
			guard let data = waypointsData else { return [] }
			return (try? JSONDecoder().decode([WaypointMarker].self, from: data)) ?? []
		}
		set {
			waypointsData = try? JSONEncoder().encode(newValue)
		}
	}
	
	var routeCoordinates: [CLLocationCoordinate2D] {
		breadcrumbCoordinates.compactMap { pair in
			guard pair.count >= 2 else { return nil }
			return CLLocationCoordinate2D(latitude: pair[0], longitude: pair[1])
		}
	}
	
	var distanceKm: Double {
		distanceMeters / 1000.0
	}
}
