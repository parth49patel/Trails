//
//  LocationManager.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation
import CoreLocation
import Observation
import CoreMotion

/// Hardware telemetry manager coordinating CoreLocation GPS streams and CoreMotion pedometer updates.
///
/// Implements modern Swift concurrency via `CLLocationUpdate.liveUpdates(.fitness)` to process
/// real-time positional updates with low energy overhead. Incorporates signal noise filtering
/// and stationary drift dampening, while simultaneously capturing live step counts through `CMPedometer`.
@Observable
@MainActor
final class LocationManager {
	
	// MARK: - Published Observable State

	/// The most recent valid user location fix.
	var userLocation: CLLocation?
	
	/// Total cumulative distance traversed during the active session, in meters.
	var totalDistanceMeters: CLLocationDistance = 0.0
	
	/// Real-time step tally streamed from the CoreMotion hardware coprocessor.
	var liveSteps: Int = 0
	
	/// Current CoreLocation system permission authorization status.
	var authorizationStatus: CLAuthorizationStatus = .notDetermined
	
	/// Indicates whether active GPS and pedometer telemetry sampling loops are running.
	var isTracking: Bool = false
	
	// MARK: - Computed Properties

	/// Derived convenience value presenting total tracked distance in kilometers.
	var totalDistanceKm: Double {
		totalDistanceMeters / 1000.0
	}
	
	// MARK: - Hardware Service Instances & Private State

	/// Underlying CoreLocation manager handling permission checks and authorization requests.
	private let clManager = CLLocationManager()
	
	/// Coprocessor pedometer service handling live step event delivery.
	private let pedometer = CMPedometer()
	
	/// Asynchronous Task wrapping the modern `CLLocationUpdate.liveUpdates` async sequence.
	private var trackingTask: Task<Void, Never>?
	
	/// The prior validated GPS location used for incremental distance delta calculations.
	private var lastValidLocation: CLLocation?
	
	// MARK: - Initialization

	/// Initializes the manager and captures initial location authorization status.
	init() {
		self.authorizationStatus = clManager.authorizationStatus
	}
	
	// MARK: - Authorization

	/// Requests foreground location authorization ("While In Use") from the user.
	func requestAuthorization() {
		clManager.requestWhenInUseAuthorization()
		self.authorizationStatus = clManager.authorizationStatus
	}
	
	// MARK: - Telemetry Lifecycle

	/// Begins continuous location streaming and step count sampling.
	///
	/// Configures the modern iOS 17+ `CLLocationUpdate.liveUpdates` stream using the `.fitness`
	/// activity profile for optimized pedestrian routing, alongside live `CMPedometer` updates.
	func startTracking() {
		guard !isTracking else { return }
		if authorizationStatus == .notDetermined { requestAuthorization() }
		
		isTracking = true
		lastValidLocation = nil
		
		// MARK: - CoreMotion Pedometer Setup
		if CMPedometer.isStepCountingAvailable() {
			pedometer.startUpdates(from: Date()) { [weak self] data, _ in
				guard let self, let data else { return }
				Task { @MainActor in
					self.liveSteps = data.numberOfSteps.intValue
				}
			}
		}
		
		// MARK: - CoreLocation Async Stream Setup
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
	
	/// Halts telemetry sampling tasks and disconnects sensor updates during paused session states.
	func pauseTracking() {
		isTracking = false
		trackingTask?.cancel()
		trackingTask = nil
		pedometer.stopUpdates()
	}
	
	/// Stops all hardware updates and resets cumulative distance, step counts, and anchor references.
	func reset() {
		pauseTracking()
		totalDistanceMeters = 0.0
		liveSteps = 0
		userLocation = nil
		lastValidLocation = nil
	}
	
	// MARK: - GPS Filtering & Signal Processing

	/// Validates raw GPS fixes and calculates cumulative pedestrian distance.
	///
	/// Non-obvious Engineering Logic:
	/// - **Accuracy Gate:** Rejects fixes with horizontal accuracy > 20 meters or negative values,
	///   preventing wild multipath reflections common in dense forest cover or urban canyons.
	/// - **Drift Guard:** Imposes a 2.5-meter minimum displacement threshold before accumulating
	///   distance to eliminate GPS "jitter" while the hiker is stationary.
	///
	/// - Parameter location: Raw incoming `CLLocation` update from the hardware pipeline.
	private func processNewLocation(_ location: CLLocation) {
		// Filter out inaccurate or invalid GPS fixes
		guard location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 20 else { return }
		
		self.userLocation = location
		
		// Accumulate distance between consecutive valid GPS fixes
		if let lastLocation = lastValidLocation {
			let delta = location.distance(from: lastLocation)
			
			// Stationary threshold check prevents GPS drift accumulation
			if delta >= 2.5 {
				totalDistanceMeters += delta
				lastValidLocation = location
			}
		} else {
			lastValidLocation = location
		}
	}
}
