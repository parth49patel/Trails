//
//  AppState.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation

enum ActiveHikeStatus {
	case idle
	case active
	case paused
}

@MainActor
@Observable
final class AppState {
	
	var availableTrails: [Trail] = []
	
	// Navigation & Sheet States
	var selectedTrail: Trail?
	var isShowingProfile: Bool = false
	var isShowingCamera: Bool = false
	
	// Active Hike Status
	var hikeStatus: ActiveHikeStatus = .idle
	var elapsedSeconds: Int = 0
	var distanceMeters: Double = 0.0
	var currentPaceMinutesPerKm: Double = 0.0
	var stepCount: Int = 0
	var userBreadcrumbs: [CLLocationCoordinate2D] = []
	var recordedWaypoints: [WaypointMarker] = []
	
	
	init() {
		self.availableTrails = TrailLoader.loadBundledTrails()
	}
	
	// UI Helpers
	var isHikeActive: Bool {
		hikeStatus == .active || hikeStatus == .paused
	}
	
	var formattedDuration: String {
		let hours = elapsedSeconds / 3600
		let minutes = (elapsedSeconds % 3600) / 60
		let seconds = elapsedSeconds % 60
		if hours > 0 {
			return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
		} else {
			return String(format: "%02d:%02d", minutes, seconds)
		}
	}
	
	var formattedDistance: String {
		String(format: "%.2f km", distanceMeters / 1000.0)
	}
	
	var formattedPace: String {
		guard currentPaceMinutesPerKm > 0 && currentPaceMinutesPerKm < 60 else { return "--:--" }
		let mins = Int(currentPaceMinutesPerKm)
		let secs = Int((currentPaceMinutesPerKm - Double(mins)) * 60)
		return String(format: "%d'%02d\"", mins, secs)
	}
	
	func startHike(for trail: Trail? = nil) {
		self.selectedTrail = trail
		self.elapsedSeconds = 0
		self.distanceMeters = 0.0
		self.currentPaceMinutesPerKm = 0.0
		self.stepCount = 0
		self.userBreadcrumbs.removeAll()
		self.recordedWaypoints.removeAll()
		self.hikeStatus = .active
	}
	
	func endHike() {
		self.hikeStatus = .idle
	}
}
