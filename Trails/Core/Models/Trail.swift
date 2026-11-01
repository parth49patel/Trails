//
//  Trail.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation

/// Represents a pre-stored trail template available for hiking sessions.
struct Trail: Identifiable, Codable, Hashable, Sendable {
	let id: String
	let name: String
	let locationName: String
	let distanceKm: Double
	let estimatedDurationMinutes: Int
	let estimatedSteps: Int
	let startLatitude: Double
	let startLongitude: Double
	
	var startCoordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: Trail, rhs: Trail) -> Bool {
		lhs.id == rhs.id
	}
}
