//
//  HikeDetailView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import MapKit
import AVKit

/// Displays the historical telemetry review, path rendering, and media playback for a recorded hike.
///
/// Features:
/// - Reconstructs the chronological route path across recorded start, pinned memory waypoints, and finish coordinates.
/// - Renders an interactive `MapKit` scene with custom annotations for route boundaries and pinned memories.
/// - Integrates embedded `AVPlayer` playback for 10-second sandbox-stored video memories.
/// - Presents the four core session metrics: total distance, active duration, pedometer steps, and memory count.
struct HikeDetailView: View {
	
	// MARK: - Properties

	/// The persisted hike entity containing telemetry and associated waypoint models.
	let hike: HikeRecord
	
	// MARK: - State

	/// Controls the viewport and camera bounds of the MapKit presentation.
	@State private var cameraPosition: MapCameraPosition = .automatic
	
	/// The currently selected waypoint memory targeted for inline playback.
	@State private var selectedWaypoint: WaypointMarker?
	
	/// The active AVPlayer instance managing local file playback.
	@State private var activePlayer: AVPlayer?
	
	// MARK: - Route Reconstruction

	/// Resolves the starting coordinate for the hike.
	private var resolvedStartCoordinate: CLLocationCoordinate2D? {
		hike.startCoordinate ?? hike.waypoints.first?.coordinate ?? hike.finishCoordinate
	}
	
	/// Returns the finish coordinate if the user walked at least 2.5 meters (matching LocationManager's filter).
	/// If the user walked a closed loop back to the exact starting coordinate, applies a tiny ~8m offset
	/// so both the Start and Finish flags and the connecting polyline remain clearly visible.
	private var resolvedFinishCoordinate: CLLocationCoordinate2D? {
		guard let finish = hike.finishCoordinate else { return nil }
		guard let start = resolvedStartCoordinate else { return finish }
		
		let startLoc = CLLocation(latitude: start.latitude, longitude: start.longitude)
		let finishLoc = CLLocation(latitude: finish.latitude, longitude: finish.longitude)
		let straightLineDist = finishLoc.distance(from: startLoc)
		
		// Enforce the 2.5m minimum displacement gate against walked distance or endpoint separation
		guard hike.distanceMeters >= 2.5 || straightLineDist >= 2.5 else {
			return nil
		}
		
		// If the user walked >= 2.5m in a loop back to the starting point, separate the flags slightly
		if straightLineDist < 2.5 {
			return CLLocationCoordinate2D(
				latitude: finish.latitude + 0.00008,
				longitude: finish.longitude + 0.00008
			)
		}
		
		return finish
	}
	
	/// Reconstructs the chronological coordinate array: Start -> Waypoints (>= 2.5m apart) -> Finish.
	/// If total displacement is less than 2.5m, only a single coordinate is returned so no polyline draws.
	private var recordedPathCoordinates: [CLLocationCoordinate2D] {
		var points: [CLLocationCoordinate2D] = []
		
		if let start = resolvedStartCoordinate {
			points.append(start)
		}
		
		for wp in hike.waypoints {
			if let last = points.last {
				let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
				let wpLoc = CLLocation(latitude: wp.latitude, longitude: wp.longitude)
				if wpLoc.distance(from: lastLoc) >= 2.5 {
					points.append(wp.coordinate)
				}
			} else {
				points.append(wp.coordinate)
			}
		}
		
		if let finish = resolvedFinishCoordinate {
			points.append(finish)
		}
		
		return points
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				// MARK: - Map View
				Map(position: $cameraPosition) {
					// Recorded Path Polyline
					if recordedPathCoordinates.count >= 2 {
						MapPolyline(coordinates: recordedPathCoordinates)
							.stroke(
								Color.accentColor,
								style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
							)
					}
					
					// Start Flag Annotation
					if let start = resolvedStartCoordinate {
						Annotation("Start", coordinate: start) {
							ZStack {
								Circle()
									.fill(Color.green)
									.frame(width: 26, height: 26)
									.overlay(Circle().stroke(Color.white, lineWidth: 2))
									.shadow(radius: 2)
								Image(systemName: "flag.fill")
									.font(.system(size: 11, weight: .bold))
									.foregroundStyle(.white)
							}
						}
					}
					
					// Finish Flag Annotation
					if let finish = resolvedFinishCoordinate {
						Annotation("Finish", coordinate: finish) {
							ZStack {
								Circle()
									.fill(Color.red)
									.frame(width: 26, height: 26)
									.overlay(Circle().stroke(Color.white, lineWidth: 2))
									.shadow(radius: 2)
								Image(systemName: "flag.checkered")
									.font(.system(size: 11, weight: .bold))
									.foregroundStyle(.white)
							}
						}
					}
					
					// Pinned Video Waypoint Pins
					ForEach(hike.waypoints) { waypoint in
						Annotation(waypoint.title, coordinate: waypoint.coordinate) {
							Button {
								playVideo(for: waypoint)
							} label: {
								ZStack {
									Circle()
										.fill(Color.white)
										.frame(width: 32, height: 32)
										.shadow(radius: 3)
									Circle()
										.fill(Color.blue)
										.frame(width: 26, height: 26)
									Image(systemName: "video.fill")
										.font(.system(size: 11, weight: .bold))
										.foregroundStyle(.white)
								}
							}
						}
					}
				}
				.mapStyle(.standard(elevation: .realistic))
				.frame(height: 300)
				.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: 18, style: .continuous)
						.stroke(Color(.separator), lineWidth: 0.5)
				)
				.padding(.horizontal, 16)
				.onAppear { centerMapOnRecordedHike() }
				
				// MARK: - Video Player Overlay
				if let waypoint = selectedWaypoint, let player = activePlayer {
					VStack(alignment: .leading, spacing: 8) {
						HStack {
							Label(waypoint.title, systemImage: "video.badge.waveform.fill")
								.font(.headline)
							Spacer()
							Button {
								player.pause()
								self.selectedWaypoint = nil
								self.activePlayer = nil
							} label: {
								Image(systemName: "xmark.circle.fill")
									.font(.title3)
									.foregroundStyle(.secondary)
							}
						}
						
						VideoPlayer(player: player)
							.frame(height: 220)
							.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
							.onAppear { player.play() }
					}
					.padding(16)
					.background(Color(.secondarySystemBackground))
					.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
					.padding(.horizontal, 16)
				}
				
				// MARK: - Core 4 Metrics Grid
				VStack(spacing: 12) {
					HStack(spacing: 12) {
						metricTile(
							label: "DISTANCE",
							value: String(format: "%.2f km", hike.distanceKm),
							icon: "figure.hiking"
						)
						metricTile(
							label: "DURATION",
							value: formatDuration(seconds: hike.durationSeconds),
							icon: "clock.fill"
						)
					}
					HStack(spacing: 12) {
						metricTile(
							label: "STEPS",
							value: hike.stepCount.formatted(),
							icon: "figure.walk"
						)
						metricTile(
							label: "MEMORIES",
							value: "\(hike.waypoints.count) pinned",
							icon: "video.fill"
						)
					}
				}
				.padding(.horizontal, 16)
			}
			.padding(.vertical, 16)
		}
		.navigationTitle(hike.trailName)
		.navigationBarTitleDisplayMode(.inline)
	}
	
	// MARK: - Video Handling

	/// Loads and triggers playback for a pinned memory waypoint from the sandboxed Documents directory.
	private func playVideo(for waypoint: WaypointMarker) {
		guard let url = waypoint.localFileURL, FileManager.default.fileExists(atPath: url.path) else {
			return
		}
		self.selectedWaypoint = waypoint
		self.activePlayer = AVPlayer(url: url)
	}
	
	// MARK: - Map Geometry & Bounds

	/// Calculates the minimum bounding box encompassing all recorded route points
	/// and smoothly centers the camera span.
	private func centerMapOnRecordedHike() {
		let points = recordedPathCoordinates
		guard !points.isEmpty else { return }
		
		if points.count == 1, let singlePoint = points.first {
			cameraPosition = .region(
				MKCoordinateRegion(
					center: singlePoint,
					span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
				)
			)
			return
		}
		
		let lats = points.map(\.latitude)
		let lons = points.map(\.longitude)
		
		guard let minLat = lats.min(), let maxLat = lats.max(),
			  let minLon = lons.min(), let maxLon = lons.max() else { return }
		
		let center = CLLocationCoordinate2D(
			latitude: (minLat + maxLat) / 2.0,
			longitude: (minLon + maxLon) / 2.0
		)
		let deltaLat = max((maxLat - minLat) * 1.6, 0.003)
		let deltaLon = max((maxLon - minLon) * 1.6, 0.003)
		
		cameraPosition = .region(
			MKCoordinateRegion(
				center: center,
				span: MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
			)
		)
	}
	
	// MARK: - Formatting Helpers
	
	@ViewBuilder
	private func metricTile(label: String, value: String, icon: String) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(spacing: 4) {
				Image(systemName: icon).font(.caption2.weight(.bold))
				Text(label).font(.caption2.weight(.bold))
			}
			.foregroundStyle(.secondary)
			
			Text(value)
				.font(.system(.title3, design: .rounded, weight: .bold))
				.monospacedDigit()
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(14)
		.background(Color(.secondarySystemBackground))
		.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
	}
	
	private func formatDuration(seconds: Int) -> String {
		let hours = seconds / 3600
		let minutes = (seconds % 3600) / 60
		let secs = seconds % 60
		return hours > 0 ? String(format: "%dh %02dm", hours, minutes) : String(format: "%dm %02ds", minutes, secs)
	}
}

#Preview {
	HikeDetailView(
		hike: HikeRecord(
			userId: "preview_user",
			trailName: "Pleasure Valley",
			distanceMeters: 2490.0,
			durationSeconds: 400,
			stepCount: 5000
		)
	)
}
