//
//  HikeRecord.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation

struct HikeRecord: Identifiable, Codable {
	let id: String
	let userId: String
	let trailName: String
	let date: Date
	let durationSeconds: Int
	let distanceKm: Double
	let averagePaceMinutesPerKm: Double
	let steps: Int
	let waypoints: [WaypointMarker]
}
