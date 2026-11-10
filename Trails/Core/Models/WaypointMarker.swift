//
//  WaypointMarker.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation
import CoreLocation

/// Represents a pinned multimedia point of interest captured during an active hike session.
///
/// Anchors a 10-second AVFoundation video recording to precise geographic coordinates, persisting
/// only the relative file name to maintain sandbox URL resilience across app updates and migrations.
struct WaypointMarker: Identifiable, Codable, Hashable, Sendable {
	
	// MARK: - Properties

	/// Unique identifier for the waypoint memory.
	let id: String
	
	/// Geographic latitude at the time of video capture.
	let latitude: Double
	
	/// Geographic longitude at the time of video capture.
	let longitude: Double
	
	/// Relative file name of the recorded `.mov` asset stored within the Documents container.
	let videoFilename: String?
	
	/// Timestamp indicating when the memory was recorded.
	let recordedAt: Date
	
	/// Display title for the waypoint annotation callout.
	let title: String
	
	// MARK: - Initialization

	/// Creates a new waypoint marker instance.
	///
	/// - Parameters:
	///   - id: Unique UUID string (defaults to a fresh `UUID`).
	///   - latitude: Geographic latitude coordinate.
	///   - longitude: Geographic longitude coordinate.
	///   - videoFilename: Local relative file name (nil if text-only pin).
	///   - recordedAt: Timestamp of creation (defaults to current date).
	///   - title: Title displayed in MapKit callouts (defaults to "Scenic Memory").
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
	
	// MARK: - Computed Properties

	/// The MapKit-compatible coordinate representation used for map annotations.
	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	/// Resolves the absolute disk URL to the video file within the sandboxed Documents directory.
	var localFileURL: URL? {
		guard let filename = videoFilename, !filename.isEmpty else { return nil }
		guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return nil
		}
		return docs.appendingPathComponent(filename)
	}
}
