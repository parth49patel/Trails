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
	
	// MARK: - Navigation & Presentation States
	var selectedTrail: Trail?
	var isShowingProfile: Bool = false
	var isShowingCamera: Bool = false
	
	// MARK: - Active Hike Telemetry (Core 4 Metrics)
	var hikeStatus: ActiveHikeStatus = .idle
	var elapsedSeconds: Int = 0
	var distanceMeters: Double = 0.0
	var stepCount: Int = 0
	var recordedWaypoints: [WaypointMarker] = []
	
	// MARK: - Location & Timing Services
	let locationManager = LocationManager()
	private var hikeTimer: Timer?
	private var telemetryObservationTask: Task<Void, Never>?
	private var sessionStartCoordinate: CLLocationCoordinate2D?
	
	var modelContext: ModelContext?
	
	init() {
		self.availableTrails = TrailLoader.loadBundledTrails()
	}
	
	// MARK: - UI Presentation Helpers
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
	
	var formattedSteps: String {
		stepCount.formatted()
	}
	
	// MARK: - Video Waypoint Recording
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
			print("✅ Pinned video waypoint: \(filename). Total waypoints: \(recordedWaypoints.count)")
		} catch {
			print("⚠️ Failed saving video locally: \(error.localizedDescription)")
		}
	}
	
	// MARK: - Hike Session Lifecycle
	func startHike(for trail: Trail? = nil) {
		self.selectedTrail = trail
		self.elapsedSeconds = 0
		self.distanceMeters = 0.0
		self.stepCount = 0
		self.recordedWaypoints.removeAll()
		self.hikeStatus = .active
		
		// Capture start anchor (selected trail coordinate, or immediate user GPS fix)
		self.sessionStartCoordinate = trail?.startCoordinate ?? locationManager.userLocation?.coordinate
		
		locationManager.reset()
		locationManager.startTracking()
		
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
		guard isHikeActive else { return }
		
		let currentUserId = Auth.auth().currentUser?.uid ?? "local_user"
		let finalDistance = distanceMeters
		let finalDuration = elapsedSeconds
		let finalSteps = stepCount
		let waypointsToSave = self.recordedWaypoints
		
		// Final coordinate reading from LocationManager
		let finishCoord = locationManager.userLocation?.coordinate
		let startCoord = self.sessionStartCoordinate ?? finishCoord
		
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
		
		self.sessionStartCoordinate = nil
		self.recordedWaypoints.removeAll()
		endHike()
	}
	
	// MARK: - Private Session Helpers
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
				
				// Pull hardware readings for core metrics
				self.distanceMeters = self.locationManager.totalDistanceMeters
				self.stepCount = self.locationManager.liveSteps
				
				try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s update cadence
			}
		}
	}
}
