//
//  Trail.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation


struct CoordinatePoint: Codable, Hashable {
	let latitude: Double
	let longitude: Double
	
	var clCoordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
}

struct Trail: Identifiable, Codable, Hashable {
	let id: String
	let name: String
	let locationName: String
	let difficulty: Difficulty
	let distanceKm: Double
	let elevationGainMeters: Int
	let estimatedDurationMinutes: Int
	let summary: String
	let startLatitude: Double
	let startLongitude: Double
	let coordinates: [CoordinatePoint]
	
	// Quick MapKit accessors
	var startCoordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
	}
	
	var routeCoordinates: [CLLocationCoordinate2D] {
		coordinates.map { $0.clCoordinate }
	}
	
	enum Difficulty: String, CaseIterable, Codable {
		case easy = "Easy"
		case moderate = "Moderate"
		case hard = "Hard"
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	static func == (lhs: Trail, rhs: Trail) -> Bool {
		lhs.id == rhs.id
	}
}
