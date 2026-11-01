//
//  WaypointMarker.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation

struct WaypointMarker: Identifiable, Codable, Hashable {
	var id: String
	var latitude: Double
	var longitude: Double
	var videoFilename: String?
	var recordedAt: Date
	var title: String
	
	init(
		id: String = UUID().uuidString,
		latitude: Double,
		longitude: Double,
		videoFilename: String? = nil,
		recordedAt: Date = Date(),
		title: String = "Scenic Memory"
	) {
		self.id = id
		self.latitude = latitude
		self.longitude = longitude
		self.videoFilename = videoFilename
		self.recordedAt = recordedAt
		self.title = title
	}
	
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	/// Dynamic sandbox URL pointing into the local Documents directory
	var localFileURL: URL? {
		guard let filename = videoFilename, !filename.isEmpty else { return nil }
		let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
		return docs.appendingPathComponent(filename)
	}
}
