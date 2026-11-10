//
//  HikeRecord.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation
import SwiftData
import CoreLocation

/// Persistent data entity representing a completed hiking session stored locally on-device.
///
/// Managed by the **SwiftData** persistence framework, this model captures:
/// - Session identity and user linkage (`userId`, `trailId`, `trailName`, `date`).
/// - Initial and terminal GPS coordinate anchors for boundary reconstruction.
/// - The four primary telemetry dimensions: elapsed duration, distance traveled, step count,
///   and an ordered collection of pinned multimedia waypoints serialized as JSON `Data`.
@Model
final class HikeRecord {
	
	// MARK: - Identifiers & Session Metadata

	/// Unique primary key guaranteeing database record uniqueness across local contexts.
	@Attribute(.unique) var id: String
	
	/// The authenticated user identifier (Firebase UID or fallback local ID).
	var userId: String
	
	/// Reference identifier of the curated trail followed, or `nil` if completed as Free Roam.
	var trailId: String?
	
	/// Display name of the route or "Free Roam Hike".
	var trailName: String
	
	/// Timestamp marking the session completion and record persistence date.
	var date: Date
	
	// MARK: - Recorded Geographic Anchors

	/// Starting latitude coordinate recorded at tracking initiation.
	var startLatitude: Double?
	
	/// Starting longitude coordinate recorded at tracking initiation.
	var startLongitude: Double?
	
	/// Terminating latitude coordinate recorded upon session completion.
	var finishLatitude: Double?
	
	/// Terminating longitude coordinate recorded upon session completion.
	var finishLongitude: Double?
	
	// MARK: - Core 4 Metrics & Serialized Storage

	/// Total cumulative distance traversed during the hike, in meters.
	var distanceMeters: Double
	
	/// Total active hiking duration, excluding paused intervals, in seconds.
	var durationSeconds: Int
	
	/// Total steps logged by the CoreMotion pedometer throughout the session.
	var stepCount: Int
	
	/// Serialized JSON blob storing the collection of `WaypointMarker` structs.
	///
	/// Preserves ordered waypoint collections without requiring a separate relational table
	/// or foreign-key cascade configuration.
	var waypointsData: Data?
	
	// MARK: - Initializer

	/// Initializes and configures a new persistent hike record.
	///
	/// - Parameters:
	///   - id: Unique UUID string identifier.
	///   - userId: User identity string.
	///   - trailId: Optional curated trail identifier.
	///   - trailName: Descriptive name for the completed hike.
	///   - distanceMeters: Total distance traveled in meters.
	///   - durationSeconds: Active duration in seconds.
	///   - stepCount: Pedometer step tally.
	///   - date: Completion timestamp (defaults to current date).
	///   - startLatitude: GPS latitude at session start.
	///   - startLongitude: GPS longitude at session start.
	///   - finishLatitude: GPS latitude at session end.
	///   - finishLongitude: GPS longitude at session end.
	///   - waypoints: Array of `WaypointMarker` objects captured along the path.
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

	/// Reconstructs the starting coordinate as a `CLLocationCoordinate2D` for MapKit annotations.
	var startCoordinate: CLLocationCoordinate2D? {
		guard let lat = startLatitude, let lon = startLongitude else { return nil }
		return CLLocationCoordinate2D(latitude: lat, longitude: lon)
	}
	
	/// Reconstructs the finishing coordinate as a `CLLocationCoordinate2D` for MapKit annotations.
	var finishCoordinate: CLLocationCoordinate2D? {
		guard let lat = finishLatitude, let lon = finishLongitude else { return nil }
		return CLLocationCoordinate2D(latitude: lat, longitude: lon)
	}
	
	/// Bridges the internal `waypointsData` JSON blob to and from strongly-typed `[WaypointMarker]` models.
	var waypoints: [WaypointMarker] {
		get {
			guard let data = waypointsData else { return [] }
			return (try? JSONDecoder().decode([WaypointMarker].self, from: data)) ?? []
		}
		set {
			waypointsData = try? JSONEncoder().encode(newValue)
		}
	}
	
	/// Computed convenience property converting base `distanceMeters` to kilometers.
	var distanceKm: Double {
		distanceMeters / 1000.0
	}
}
