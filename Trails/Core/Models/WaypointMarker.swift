//
//  WaypointMarker.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation

/// Represents a pinned memory captured along a trail, linking geographic coordinates
/// to a localized video recording stored in the application's Documents directory.
struct WaypointMarker: Identifiable, Codable, Hashable, Sendable {
	
	let id: String
	let latitude: Double
	let longitude: Double
	let videoFilename: String?
	let recordedAt: Date
	let title: String
	
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
	
	/// The MapKit-compatible geographic coordinate for placing this pin on a map.
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	/// The resolved file URL pointing directly to the video in the user's `Documents` sandbox.
	var localFileURL: URL? {
		guard let filename = videoFilename, !filename.isEmpty else { return nil }
		guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return nil
		}
		return docs.appendingPathComponent(filename)
	}
}
