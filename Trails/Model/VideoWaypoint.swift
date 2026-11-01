//
//  VideoWaypoint.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-30.
//

import Foundation
import CoreLocation

struct VideoWaypoint: Identifiable, Codable {
		var id: String = UUID().uuidString
		var latitude: Double
		var longitude: Double
		var filename: String // Stored locally in Documents directory
		var timestamp: Date = Date()
		
		var coordinate: CLLocationCoordinate2D {
				CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		}
		
		/// Resolves the actual dynamic URL on the device
		var localFileURL: URL {
				let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
				return docs.appendingPathComponent(filename)
		}
}
