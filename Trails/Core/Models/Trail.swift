//
//  Trail.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation
import CoreLocation

/// Represents an immutable curated trail template available for exploration and tracking.
///
/// Encapsulates baseline route telemetry (distance, estimated duration, step counts) alongside
/// geographic trailhead coordinates. Conforms to `Sendable` and `Codable` for thread-safe
/// transport across concurrent Swift tasks and bundle decoding.
struct Trail: Identifiable, Codable, Hashable, Sendable {
	
	// MARK: - Properties

	/// Unique stable identifier for the trail.
	let id: String
	
	/// The public display name of the trail route.
	let name: String
	
	/// The geographic park, conservation area, or municipality housing the route.
	let locationName: String
	
	/// Anticipated path distance measured in kilometers.
	let distanceKm: Double
	
	/// Estimated time to complete the route under average hiking conditions, in minutes.
	let estimatedDurationMinutes: Int
	
	/// Approximate pedometer step count projected for completion.
	let estimatedSteps: Int
	
	/// Latitude component of the starting trailhead anchor.
	let startLatitude: Double
	
	/// Longitude component of the starting trailhead anchor.
	let startLongitude: Double
	
	// MARK: - Computed Properties

	/// Converts persistent latitude and longitude primitives into a MapKit-ready `CLLocationCoordinate2D`.
	var startCoordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
	}
	
	// MARK: - Hashable & Equatable
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: Trail, rhs: Trail) -> Bool {
		lhs.id == rhs.id
	}
}
