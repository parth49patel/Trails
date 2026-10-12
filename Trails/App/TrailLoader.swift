//
//  TrailLoader.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-09.
//

import Foundation

enum TrailLoader {
	static func loadBundledTrails() -> [Trail] {
		guard let url = Bundle.main.url(forResource: "trails", withExtension: "json") else {
			print("Error: trails.json file not found in bundle.")
			return []
		}
		
		do {
			let data = try Data(contentsOf: url)
			let decoder = JSONDecoder()
			return try decoder.decode([Trail].self, from: data)
		} catch {
			print("Error decoding trails.json: \(error)")
			return []
		}
	}
}
