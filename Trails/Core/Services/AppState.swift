	//
	//  AppState.swift
	//  Trails
	//
	//  Course: SOFE4640U Mobile Application Development
	//  Group:  10
	//

import Foundation
import CoreLocation
import SwiftData
import FirebaseAuth

/// Represents the discrete lifecycle phases of a hiking session.
enum ActiveHikeStatus {
	/// No active session in progress; map and bottom sheet are in browsing mode.
	case idle
	/// Real-time tracking is actively sampling sensors, accumulating distance, and ticking duration.
	case active
	/// Session is temporarily suspended; timers and sensor streams are halted.
	case paused
}

/// The central state machine and coordinator for the Trails application.
///
/// Manages application-wide states, including:
/// - Trail catalog discovery and selection state.
/// - Live session telemetry streaming across the four core metrics (duration, distance, steps, pinned memories).
/// - Sensor coordination between `LocationManager` and the active session timer.
/// - On-device multimedia file management within the sandboxed Documents directory.
/// - Transactional compilation and persistence of completed sessions to **SwiftData**.
@MainActor
@Observable
final class AppState {
	
	// MARK: - Catalog & Available Trails

	/// The collection of curated trail templates available for browsing and navigation.
	var availableTrails: [Trail] = []
	
	// MARK: - Navigation & Presentation States

	/// The currently selected trail, used to anchor map camera positioning and session metadata.
	var selectedTrail: Trail?
	
	/// Governs presentation of the user profile and lifetime history sheet.
	var isShowingProfile: Bool = false
	
	/// Governs presentation of the full-screen AVFoundation video capture sheet.
	var isShowingCamera: Bool = false
	
	// MARK: - Active Hike Telemetry (Core 4 Metrics)

	/// Current tracking status of the hiking session (.idle, .active, or .paused).
	var hikeStatus: ActiveHikeStatus = .idle
	
	/// Total elapsed active duration in seconds, excluding paused intervals.
	var elapsedSeconds: Int = 0
	
	/// Total accumulated hiking distance in meters, derived from validated GPS fixes.
	var distanceMeters: Double = 0.0
	
	/// Total step count recorded by the CoreMotion pedometer for the active session.
	var stepCount: Int = 0
	
	/// Ordered collection of video memory markers pinned during the active session.
	var recordedWaypoints: [WaypointMarker] = []
	
	// MARK: - Location & Timing Services

	/// Hardware telemetry manager handling GPS streaming and CoreMotion pedometer updates.
	let locationManager = LocationManager()
	
	/// Repeating timer firing every second to increment `elapsedSeconds` during active tracking.
	private var hikeTimer: Timer?
	
	/// Background polling task syncing live sensor readings from `LocationManager` to observable state.
	private var telemetryObservationTask: Task<Void, Never>?
	
	/// The initial GPS coordinate recorded at session start, anchoring route reconstruction.
	private var sessionStartCoordinate: CLLocationCoordinate2D?
	
	/// The active SwiftData context used to persist completed hike records.
	var modelContext: ModelContext?
	
	// MARK: - Initialization

	/// Initializes AppState and seeds available routes using the defensive `TrailLoader`.
	init() {
		self.availableTrails = TrailLoader.loadBundledTrails()
	}
	
	// MARK: - UI Presentation Helpers

	/// Indicates whether a hiking session is either actively recording or paused.
	var isHikeActive: Bool {
		hikeStatus == .active || hikeStatus == .paused
	}
	
	/// Formats active duration into standard `HH:MM:SS` or `MM:SS` display strings.
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
	
	/// Formats accumulated distance into a localized kilometer string (e.g., "3.45 km").
	var formattedDistance: String {
		String(format: "%.2f km", distanceMeters / 1000.0)
	}
	
	/// Formats the current step tally into a localized number string.
	var formattedSteps: String {
		stepCount.formatted()
	}
	
	// MARK: - Video Waypoint Recording

	/// Copies a captured temporary video asset into the persistent sandboxed Documents container
	/// and anchors it to the user's current GPS coordinates as a `WaypointMarker`.
	///
	/// Non-obvious Engineering Logic:
	/// - `UIImagePickerController` writes output to the system `/tmp` directory, which iOS can purge
	///   arbitrarily under memory pressure or between app launches.
	/// - Copying to `Documents` ensures permanent offline availability, while storing only the
	///   relative file name in the model ensures URLs remain valid across container UUID migrations.
	///
	/// - Parameter sourceURL: The temporary file system URL provided by the video picker.
	func recordVideoWaypoint(sourceURL: URL) {
		guard let coordinate = locationManager.userLocation?.coordinate else {
			print("⚠️ No coordinate available to pin video.")
			return
		}
		
		let filename = "waypoint_\(UUID().uuidString).mp4"
		guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			return
		}
		let destURL = docs.appendingPathComponent(filename)
		
		do {
			if FileManager.default.fileExists(atPath: destURL.path) {
				try FileManager.default.removeItem(at: destURL)
			}
			try FileManager.default.copyItem(at: sourceURL, to: destURL)
			
			let newWaypoint = WaypointMarker(
				latitude: coordinate.latitude,
				longitude: coordinate.longitude,
				videoFilename: filename,
				recordedAt: Date(),
				title: "Scenic Memory"
			)
			recordedWaypoints.append(newWaypoint)
			print("Pinned video waypoint: \(filename). Total waypoints: \(recordedWaypoints.count)")
		} catch {
			print("Failed saving video locally: \(error.localizedDescription)")
		}
	}
	
	// MARK: - Hike Session Lifecycle

	/// Initiates a new tracking session for a specific trail or an unguided Free Roam hike.
	///
	/// Resets all cumulative metrics, captures the initial coordinate anchor before resetting
	/// the location manager, begins sensor streaming, and starts the 1 Hz duration timer.
	///
	/// - Parameter trail: The curated trail selected by the user, or `nil` for Free Roam.
	func startHike(for trail: Trail? = nil) {
		let preResetCoord = locationManager.userLocation?.coordinate
		
		self.selectedTrail = trail
		self.elapsedSeconds = 0
		self.distanceMeters = 0.0
		self.stepCount = 0
		self.recordedWaypoints.removeAll()
		self.hikeStatus = .active
		
		// Anchor start coordinate immediately using selected trailhead or pre-reset GPS fix
		self.sessionStartCoordinate = trail?.startCoordinate ?? preResetCoord
		
		locationManager.reset()
		locationManager.startTracking()
		
		AudioService.shared.reset(interruptSpeech: true)
		let targetName = trail?.name ?? "Hike"
		AudioService.shared.speak("Starting \(targetName).")
		
		startTimer()
		bindLocationTelemetry()
	}
	
	/// Suspends an active hike, halting duration timing and sensor streaming to conserve battery.
	func pauseHike() {
		guard hikeStatus == .active else { return }
		hikeStatus = .paused
		stopTimer()
		locationManager.pauseTracking()
		AudioService.shared.speak("Hike paused.")
	}
	
	/// Resumes tracking from a paused state, restoring timer updates and sensor sampling.
	func resumeHike() {
		guard hikeStatus == .paused else { return }
		hikeStatus = .active
		startTimer()
		locationManager.startTracking()
		bindLocationTelemetry()
		AudioService.shared.speak("Resuming hike.")
	}
	
	/// Cancels or tears down the current session without persisting records to disk.
	func endHike() {
		self.hikeStatus = .idle
		stopTimer()
		telemetryObservationTask?.cancel()
		locationManager.reset()
		AudioService.shared.reset(interruptSpeech: false)
	}
	
	/// Finalizes the active hike session, compiles telemetry data into a `HikeRecord`,
	/// persists it to SwiftData, and resets the tracking state.
	func endAndSaveHike() {
		guard isHikeActive else { return }
		
		let currentUserId = Auth.auth().currentUser?.uid ?? "local_user"
		let finalDistance = distanceMeters
		let finalDuration = elapsedSeconds
		let finalSteps = stepCount
		let waypointsToSave = self.recordedWaypoints
		
		// Use the exact first and last validated GPS fixes from LocationManager
		let startCoord = locationManager.firstValidLocation?.coordinate
		?? self.sessionStartCoordinate
		?? selectedTrail?.startCoordinate
		?? waypointsToSave.first?.coordinate
		
		let finishCoord = locationManager.lastValidLocation?.coordinate
		?? locationManager.userLocation?.coordinate
		?? waypointsToSave.last?.coordinate
		?? startCoord
		
		let record = HikeRecord(
			userId: currentUserId,
			trailId: selectedTrail?.id,
			trailName: selectedTrail?.name ?? "Free Roam Hike",
			distanceMeters: finalDistance,
			durationSeconds: finalDuration,
			stepCount: finalSteps,
			date: Date(),
			startLatitude: startCoord?.latitude,
			startLongitude: startCoord?.longitude,
			finishLatitude: finishCoord?.latitude,
			finishLongitude: finishCoord?.longitude,
			waypoints: waypointsToSave
		)
		
		if let context = modelContext {
			context.insert(record)
			try? context.save()
		}
		
		// Announce hike completion summary aloud
		let distanceFormatted = String(format: "%.2f", finalDistance / 1000.0)
		AudioService.shared.speak(
			"Hike ended and saved. Total distance \(distanceFormatted) kilometers and \(finalSteps) steps."
		)
		
		self.sessionStartCoordinate = nil
		self.recordedWaypoints.removeAll()
		endHike()
	}
	
	// MARK: - Private Session Helpers

	/// Starts the 1-second interval timer driving session duration tracking.
	private func startTimer() {
		hikeTimer?.invalidate()
		hikeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
			guard let self else { return }
			self.elapsedSeconds += 1
		}
	}
	
	/// Invalidates and releases the duration tracking timer.
	private func stopTimer() {
		hikeTimer?.invalidate()
		hikeTimer = nil
	}
	
	/// Binds an asynchronous loop polling live metrics from `LocationManager` at a 2 Hz cadence (every 0.5s).
	///
	/// Decouples raw sensor callback rates from SwiftUI view invalidation schedules to maintain 60 FPS UI fluidness.
	private func bindLocationTelemetry() {
		telemetryObservationTask?.cancel()
		telemetryObservationTask = Task { [weak self] in
			while !Task.isCancelled {
				guard let self, self.hikeStatus == .active else { break }
				
				// Lock in the starting coordinate as soon as the first valid GPS fix arrives
				if self.sessionStartCoordinate == nil,
				   let firstFix = self.locationManager.firstValidLocation?.coordinate ?? self.locationManager.userLocation?.coordinate {
					self.sessionStartCoordinate = firstFix
				}
				
				// Pull hardware readings for core metrics
				self.distanceMeters = self.locationManager.totalDistanceMeters
				self.stepCount = self.locationManager.liveSteps
				
				// Check for 1 km audio milestones
				AudioService.shared.evaluateMilestone(distanceMeters: self.distanceMeters)
				
				try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s update cadence
			}
		}
	}
}
