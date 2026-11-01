//
//  TrailLoader.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-09.
//

import Foundation

enum TrailLoader {
	/// Loads the initial pre-stored trails from `trails.json` if bundled, falling back to in-memory `MockData.sampleTrails`.
	static func loadBundledTrails() -> [Trail] {
		guard let url = Bundle.main.url(forResource: "trails", withExtension: "json"),
			  let data = try? Data(contentsOf: url),
			  let decoded = try? JSONDecoder().decode([Trail].self, from: data),
			  !decoded.isEmpty else {
			// Fallback ensures the 6 pre-stored trails always populate
			return MockData.sampleTrails
		}
		
		return decoded
	}
}
