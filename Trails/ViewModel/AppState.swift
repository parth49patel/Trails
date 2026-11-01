//
//  AppState.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import Foundation
import CoreLocation
import SwiftData
import FirebaseAuth

enum ActiveHikeStatus {
	case idle
	case active
	case paused
}

@MainActor
@Observable
final class AppState {
	
	var availableTrails: [Trail] = []
	
	// MARK: - Navigation & Sheet States
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
	
	var modelContext: ModelContext?
	
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
	
	// MARK: - Video Waypoint Recording
	func recordVideoWaypoint(sourceURL: URL) {
		// Use userBreadcrumbs or the userLocation property on LocationManager
		guard let coordinate = userBreadcrumbs.last ?? locationManager.userLocation?.coordinate else {
			print("⚠️ No coordinate available to pin video.")
			return
		}
		
		let filename = "waypoint_\(UUID().uuidString).mp4"
		let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
			AudioService.shared.speak("Memory video pinned to route.")
			print("✅ Pinned video waypoint: \(filename). Total waypoints: \(recordedWaypoints.count)")
		} catch {
			print("⚠️ Failed saving video locally: \(error.localizedDescription)")
		}
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
		
		// Audio announcement & milestone tracker reset
		AudioService.shared.reset()
		let trailTitle = trail?.name ?? "Free Roam"
		AudioService.shared.speak("Starting \(trailTitle). Tracking your route.")
		
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
		AudioService.shared.speak("Hike paused.")
	}
	
	func resumeHike() {
		guard hikeStatus == .paused else { return }
		hikeStatus = .active
		startTimer()
		locationManager.startTracking()
		bindLocationTelemetry()
		AudioService.shared.speak("Resume hike.")
	}
	
	func endHike() {
		self.hikeStatus = .idle
		stopTimer()
		telemetryObservationTask?.cancel()
		locationManager.reset()
	}
	
	func endAndSaveHike() {
		guard isHikeActive else { return }
		
		let currentUserId = Auth.auth().currentUser?.uid ?? "guest_user"
		let finalDistance = distanceMeters
		let finalDuration = elapsedSeconds
		let finalElevation = elevationGainMeters
		let finalSteps = stepCount
		let avgPace = finalDistance > 0 ? (Double(finalDuration) / (finalDistance / 1000.0)) : nil
		let serializedCoords = userBreadcrumbs.map { [$0.latitude, $0.longitude] }
		let waypointsToSave = self.recordedWaypoints
		
		AudioService.shared.speak("Hike complete. Great job!")
		
		// 1. Create record with the local waypoints
		let record = HikeRecord(
			userId: currentUserId,
			trailId: selectedTrail?.id,
			trailName: selectedTrail?.name ?? "Free Roam Hike",
			distanceMeters: finalDistance,
			durationSeconds: finalDuration,
			elevationGainMeters: finalElevation,
			stepCount: finalSteps,
			averagePaceSecondsPerKm: avgPace,
			date: Date(),
			breadcrumbCoordinates: serializedCoords,
			waypoints: waypointsToSave,
			isSyncedToCloud: false
		)
		
		// 2. Persist to SwiftData
		if let context = modelContext {
			context.insert(record)
			do {
				try context.save()
				print("✅ Successfully saved hike \(record.id) to SwiftData with \(record.waypoints.count) waypoints.")
			} catch {
				print("⚠️ Failed saving hike to SwiftData: \(error.localizedDescription)")
			}
		}
		
		// 3. Reset live session state
		self.recordedWaypoints.removeAll()
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
				
				// Pull hardware readings from LocationManager
				self.distanceMeters = self.locationManager.totalDistanceMeters
				self.userBreadcrumbs = self.locationManager.breadcrumbs
				self.currentPaceMinutesPerKm = self.locationManager.currentPaceMinPerKm ?? 0.0
				self.currentAltitudeMeters = self.locationManager.currentAltitudeMeters
				self.elevationGainMeters = self.locationManager.elevationGainMeters
				self.stepCount = self.locationManager.liveSteps
				
				// Evaluate audio milestone triggers
				AudioService.shared.evaluateMilestone(
					distanceMeters: self.distanceMeters,
					formattedPace: self.formattedPace,
					elevationGainMeters: self.elevationGainMeters
				)
				
				try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s update cadence
			}
		}
	}
}
