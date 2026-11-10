//
//  TrailLoader.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation

/// Utility responsible for seeding and populating baseline trail catalog records.
///
/// Implemented as an uninhabited enum namespace to disallow instantiation while providing
/// defensive fallback mechanisms during asset extraction.
enum TrailLoader {
	
	// MARK: - Bundle Decoding

	/// Reads and decodes curated trail definitions packaged within the application bundle.
	///
	/// Attempts to locate and parse `trails.json`. If the file is missing, unreadable, or malformed,
	/// it fails gracefully by returning `MockData.sampleTrails` to ensure offline readiness and
	/// guarantee that the map and bottom sheet interfaces are never left in an unpopulated state.
	///
	/// - Returns: An array of validated `Trail` models.
	static func loadBundledTrails() -> [Trail] {
		guard let url = Bundle.main.url(forResource: "trails", withExtension: "json"),
			  let data = try? Data(contentsOf: url),
			  let decoded = try? JSONDecoder().decode([Trail].self, from: data),
			  !decoded.isEmpty else {
			// Defensive fallback guarantees the core curated trails populate under all runtime conditions
			return MockData.sampleTrails
		}
		
		return decoded
	}
}
