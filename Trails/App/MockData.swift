//
//  MockData.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation

enum MockData {
	static let sampleTrails: [Trail] = [
		Trail(
			id: "trail_01",
			name: "Ridge Crest Loop",
			locationName: "Highland Provincial Park",
			distanceKm: 5.4,
			estimatedDurationMinutes: 95,
			estimatedSteps: 7200,
			startLatitude: 49.2827,
			startLongitude: -123.1207
		),
		Trail(
			id: "trail_02",
			name: "Whispering Pines Path",
			locationName: "Emerald Forest Reserve",
			distanceKm: 3.2,
			estimatedDurationMinutes: 45,
			estimatedSteps: 4300,
			startLatitude: 49.2910,
			startLongitude: -123.1350
		),
		Trail(
			id: "trail_03",
			name: "Summit Boulder Scramble",
			locationName: "Granite Peak Range",
			distanceKm: 8.1,
			estimatedDurationMinutes: 190,
			estimatedSteps: 11000,
			startLatitude: 49.3000,
			startLongitude: -123.1100
		),
		Trail(
			id: "trail_04",
			name: "Cedar Valley Ramble",
			locationName: "Cascadia Provincial Park",
			distanceKm: 4.8,
			estimatedDurationMinutes: 70,
			estimatedSteps: 6400,
			startLatitude: 49.3200,
			startLongitude: -123.1500
		),
		Trail(
			id: "trail_05",
			name: "Eagle View Lookout",
			locationName: "Coastal Ridge Park",
			distanceKm: 6.2,
			estimatedDurationMinutes: 110,
			estimatedSteps: 8300,
			startLatitude: 49.3350,
			startLongitude: -123.1650
		),
		Trail(
			id: "trail_06",
			name: "Old Logging Road Loop",
			locationName: "Timber Ridge Valley",
			distanceKm: 9.5,
			estimatedDurationMinutes: 150,
			estimatedSteps: 12800,
			startLatitude: 49.3500,
			startLongitude: -123.1800
		)
	]
}
