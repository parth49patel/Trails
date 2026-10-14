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
	
	// MARK: -  Navigation & Sheet States
	var selectedTrail: Trail?
	var isShowingProfile: Bool = false
	var isShowingCamera: Bool = false
	
	// MARK: - Active Hike Status & Telemetry
	var hikeStatus: ActiveHikeStatus = .idle
	var elapsedSeconds: Int = 0
	var distanceMeters: Double = 0.0
	var currentPaceMinutesPerKm: Double = 0.0
	var stepCount: Int = 0
	var currentAltitudeMeters: Double = 0.0
	var elevationGainMeters: Double = 0.0
	var userBreadcrumbs: [CLLocationCoordinate2D] = []
	var recordedWaypoints: [WaypointMarker] = []
	
	// MARK: - Services & Timers
	let locationManager = LocationManager()
	private var hikeTimer: Timer?
	private var telemetryObservationTask: Task<Void, Never>?
	
	init() {
		self.availableTrails = TrailLoader.loadBundledTrails()
	}
	
	// MARK: - UI Helpers
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
	
	var formattedAltitude: String {
		String(format: "%.0f m", currentAltitudeMeters)
	}

	var formattedElevationGain: String {
		String(format: "+%.0f m", elevationGainMeters)
	}

	var formattedSteps: String {
		stepCount.formatted()
	}
	
	// MARK: - Hike Lifecycle Controls
	func startHike(for trail: Trail? = nil) {
		self.selectedTrail = trail
		self.elapsedSeconds = 0
		self.distanceMeters = 0.0
		self.currentPaceMinutesPerKm = 0.0
		self.stepCount = 0
		self.userBreadcrumbs.removeAll()
		self.recordedWaypoints.removeAll()
		self.hikeStatus = .active
		
		// Reset and start GPS stream
		locationManager.reset()
		locationManager.startTracking()
		
		// Start Live Sync & Timer
		startTimer()
		bindLocationTelemetry()
	}
	
	func pauseHike() {
		guard hikeStatus == .active else { return }
		hikeStatus = .paused
		stopTimer()
		locationManager.pauseTracking()
	}
	
	func resumeHike() {
		guard hikeStatus == .paused else { return }
		hikeStatus = .active
		startTimer()
		locationManager.startTracking()
		bindLocationTelemetry()
	}
	
	func endHike() {
		self.hikeStatus = .idle
		stopTimer()
		telemetryObservationTask?.cancel()
		locationManager.reset()
	}
	
	func endAndSaveHike() {
		endHike()
	}
	
	// MARK: - Private Helpers
	private func startTimer() {
		hikeTimer?.invalidate()
		hikeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
			guard let self else { return }
			self.elapsedSeconds += 1
		}
	}
	
	private func stopTimer() {
		hikeTimer?.invalidate()
		hikeTimer = nil
	}
	
	private func bindLocationTelemetry() {
		telemetryObservationTask?.cancel()
		telemetryObservationTask = Task { [weak self] in
			while !Task.isCancelled {
				guard let self, self.hikeStatus == .active else { break }
				
				self.distanceMeters = self.locationManager.totalDistanceMeters
				self.userBreadcrumbs = self.locationManager.breadcrumbs
				self.currentPaceMinutesPerKm = self.locationManager.currentPaceMinPerKm ?? 0.0
				self.currentAltitudeMeters = self.locationManager.currentAltitudeMeters
				self.elevationGainMeters = self.locationManager.elevationGainMeters
				self.stepCount = self.locationManager.liveSteps
				
				try? await Task.sleep(nanoseconds: 500_000_000)
			}
		}
	}
}
