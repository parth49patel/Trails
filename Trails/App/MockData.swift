//
//  MockData.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation

enum MockData {
	static let sampleTrails: [Trail] = [
		Trail(
			id: "trail_01",
			name: "Ridge Crest Loop",
			locationName: "Highland Provincial Park",
			difficulty: .moderate,
			distanceKm: 5.4,
			elevationGainMeters: 280,
			estimatedDurationMinutes: 95,
			summary: "A scenic ridge trail with panoramic valley views and rocky summits.",
			startLatitude: 49.2827,
			startLongitude: -123.1207,
			coordinates: [
				CoordinatePoint(latitude: 49.2827, longitude: -123.1207),
				CoordinatePoint(latitude: 49.2845, longitude: -123.1235),
				CoordinatePoint(latitude: 49.2870, longitude: -123.1260),
				CoordinatePoint(latitude: 49.2895, longitude: -123.1230),
				CoordinatePoint(latitude: 49.2865, longitude: -123.1180),
				CoordinatePoint(latitude: 49.2827, longitude: -123.1207)
			]
		),
		Trail(
			id: "trail_02",
			name: "Whispering Pines Path",
			locationName: "Emerald Forest Reserve",
			difficulty: .easy,
			distanceKm: 3.2,
			elevationGainMeters: 85,
			estimatedDurationMinutes: 45,
			summary: "Gentle forest path shaded by towering hemlocks and tranquil brooks.",
			startLatitude: 49.2910,
			startLongitude: -123.1350,
			coordinates: [
				CoordinatePoint(latitude: 49.2910, longitude: -123.1350),
				CoordinatePoint(latitude: 49.2930, longitude: -123.1375),
				CoordinatePoint(latitude: 49.2955, longitude: -123.1410),
				CoordinatePoint(latitude: 49.2980, longitude: -123.1435)
			]
		),
		Trail(
			id: "trail_03",
			name: "Summit Boulder Scramble",
			locationName: "Granite Peak Range",
			difficulty: .hard,
			distanceKm: 8.1,
			elevationGainMeters: 620,
			estimatedDurationMinutes: 190,
			summary: "Challenging vertical ascent with steep boulder sections leading to a 360° summit.",
			startLatitude: 49.3000,
			startLongitude: -123.1100,
			coordinates: [
				CoordinatePoint(latitude: 49.3000, longitude: -123.1100),
				CoordinatePoint(latitude: 49.3040, longitude: -123.1070),
				CoordinatePoint(latitude: 49.3090, longitude: -123.1020),
				CoordinatePoint(latitude: 49.3140, longitude: -123.0980)
			]
		)
	]
}
