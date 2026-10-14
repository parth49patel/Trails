//
//  LocationManager.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-13.
//

import Foundation
import CoreLocation
import Observation
import CoreMotion

@Observable
@MainActor
final class LocationManager {
	// MARK: - Published Observable State
	var userLocation: CLLocation?
	var breadcrumbs: [CLLocationCoordinate2D] = []
	var totalDistanceMeters: CLLocationDistance = 0.0
	var currentSpeedInMetersPerSecond: Double = 0.0
	var authorizationStatus: CLAuthorizationStatus = .notDetermined
	var isTracking: Bool = false
	
	var currentAltitudeMeters: Double = 0.0
	var elevationGainMeters: Double = 0.0
	var liveSteps: Int = 0
	
	// Derived UI helpers
	var totalDistanceKm: Double {
		totalDistanceMeters / 1000.0
	}
	
	// Pace in minutes per kilometer
	var currentPaceMinPerKm: Double? {
		guard currentSpeedInMetersPerSecond > 0.5 else { return nil }
		let speedKmPerMin = (currentSpeedInMetersPerSecond * 60.0) / 1000.0
		return 1.0 / speedKmPerMin
	}
	
	// MARK: - Private properties
	private let clManager = CLLocationManager()
	private let pedometer = CMPedometer()
	private var trackingTask: Task<Void, Never>?
	private var lastValidLocation: CLLocation?
	private var startAltitude: Double?
	
	init() {
		self.authorizationStatus = clManager.authorizationStatus
	}
	
	// MARK: - Permissions
	func requestAuthorization() {
		clManager.requestWhenInUseAuthorization()
		self.authorizationStatus = clManager.authorizationStatus
	}
	
	// MARK: - Tracking Lifecycle
	func startTracking() {
		guard !isTracking else { return }
		if authorizationStatus == .notDetermined { requestAuthorization() }
		
		isTracking = true
		lastValidLocation = nil
		startAltitude = nil
		
		// Start CoreMotion Pedometer
		if CMPedometer.isStepCountingAvailable() {
			pedometer.startUpdates(from: Date()) { [weak self] data, _ in
				guard let self, let data else { return }
				Task { @MainActor in
					self.liveSteps = data.numberOfSteps.intValue
				}
			}
		}
		
		
		// Strat CoreLocation Async Stream
		trackingTask?.cancel()
		trackingTask = Task { [weak self] in
			do {
				let updates = CLLocationUpdate.liveUpdates(.fitness)
				
				for try await update in updates {
					guard !Task.isCancelled else { break }
					guard let self else { break }
					
					if let location = update.location {
						self.processNewLocation(location)
					}
				}
			} catch {
				print("Location update stream error: \(error.localizedDescription)")
			}
		}
	}
	
	func pauseTracking() {
		isTracking = false
		trackingTask?.cancel()
		trackingTask = nil
		pedometer.stopUpdates()
	}
	
	func reset() {
		pauseTracking()
		breadcrumbs.removeAll()
		totalDistanceMeters = 0.0
		currentSpeedInMetersPerSecond = 0.0
		currentAltitudeMeters = 0.0
		elevationGainMeters = 0.0
		liveSteps = 0
		userLocation = nil
		lastValidLocation = nil
		startAltitude = nil
	}
	
	// MARK: - GPS Filtering & Distance Calculation
	private func processNewLocation(_ location: CLLocation) {
		guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 20 else { return }
		
		self.userLocation = location
		self.currentSpeedInMetersPerSecond = max(0, location.speed)
		
		// Altitude & Elevation Gain
		if location.verticalAccuracy >= 0 && location.verticalAccuracy <= 20 {
			let alt = location.altitude
			self.currentAltitudeMeters = alt
			
			if let prev = lastValidLocation, alt > prev.altitude {
				self.elevationGainMeters += (alt - prev.altitude)
			}
		}
		
		// Distance & Breadcrumbs
		if let lastLocation = lastValidLocation {
			let delta = location.distance(from: lastLocation)
			
			if delta >= 2.5 {
				totalDistanceMeters += delta
				breadcrumbs.append(location.coordinate)
				lastValidLocation = location
			}
		} else {
			breadcrumbs.append(location.coordinate)
			lastValidLocation = location
		}
	}
}
