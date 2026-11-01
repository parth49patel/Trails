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
	var totalDistanceMeters: CLLocationDistance = 0.0
	var liveSteps: Int = 0
	var authorizationStatus: CLAuthorizationStatus = .notDetermined
	var isTracking: Bool = false
	
	// Derived UI helper
	var totalDistanceKm: Double {
		totalDistanceMeters / 1000.0
	}
	
	// MARK: - Private Hardware Services
	private let clManager = CLLocationManager()
	private let pedometer = CMPedometer()
	private var trackingTask: Task<Void, Never>?
	private var lastValidLocation: CLLocation?
	
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
		
		// Start CoreMotion Pedometer for step counting
		if CMPedometer.isStepCountingAvailable() {
			pedometer.startUpdates(from: Date()) { [weak self] data, _ in
				guard let self, let data else { return }
				Task { @MainActor in
					self.liveSteps = data.numberOfSteps.intValue
				}
			}
		}
		
		// Start CoreLocation live update stream (.fitness activity profile)
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
		totalDistanceMeters = 0.0
		liveSteps = 0
		userLocation = nil
		lastValidLocation = nil
	}
	
	// MARK: - GPS Filtering & Distance Calculation
	private func processNewLocation(_ location: CLLocation) {
		// Filter out noisy GPS readings (> 20 meters horizontal inaccuracy)
		guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 20 else { return }
		
		self.userLocation = location
		
		// Accumulate distance between consecutive valid GPS fixes
		if let lastLocation = lastValidLocation {
			let delta = location.distance(from: lastLocation)
			
			// 2.5m minimum step prevents GPS drift while stationary
			if delta >= 2.5 {
				totalDistanceMeters += delta
				lastValidLocation = location
			}
		} else {
			lastValidLocation = location
		}
	}
}
