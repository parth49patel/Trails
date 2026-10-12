//
//  WaypointMarker.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation

struct WaypointMarker: Identifiable, Codable {
	let id: String
	let latitude: Double
	let longitude: Double
	let videoURLString: String?
	let recordedAt: Date
	let title: String
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
}
