//
//  HikeDetailView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import SwiftUI
import MapKit
import AVKit

/// Presents detailed metrics, user-recorded start/finish points, connecting path,
/// and pinned video memories for a recorded hike.
struct HikeDetailView: View {
	
	let hike: HikeRecord
	
	@State private var cameraPosition: MapCameraPosition = .automatic
	@State private var selectedWaypoint: WaypointMarker?
	@State private var activePlayer: AVPlayer?
	
	// MARK: - Recorded Route Progression
	/// Sequence: [Recorded Start] -> [Memory Waypoints in Order] -> [Recorded Finish]
	private var recordedPathCoordinates: [CLLocationCoordinate2D] {
		var points: [CLLocationCoordinate2D] = []
		
		if let start = hike.startCoordinate {
			points.append(start)
		}
		
		for wp in hike.waypoints {
			points.append(wp.coordinate)
		}
		
		if let finish = hike.finishCoordinate {
			// Avoid duplicate identical point at the tail
			if let last = points.last {
				if abs(last.latitude - finish.latitude) > 0.00005 || abs(last.longitude - finish.longitude) > 0.00005 {
					points.append(finish)
				}
			} else {
				points.append(finish)
			}
		}
		
		return points
	}
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				// MARK: - Map with Start, Finish, Route & Memories
				Map(position: $cameraPosition) {
						// Recorded Path Polyline
					if recordedPathCoordinates.count >= 2 {
						MapPolyline(coordinates: recordedPathCoordinates)
							.stroke(
								Color.accentColor,
								style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
							)
					}
					
					// Recorded Start Marker
					if let start = hike.startCoordinate {
						Annotation("Start", coordinate: start) {
							ZStack {
								Circle()
									.fill(Color.green)
									.frame(width: 24, height: 24)
									.overlay(Circle().stroke(Color.white, lineWidth: 2))
									.shadow(radius: 2)
								Image(systemName: "flag.fill")
									.font(.system(size: 10, weight: .bold))
									.foregroundStyle(.white)
							}
						}
					}
					
					// Recorded Finish Marker
					if let finish = hike.finishCoordinate, isDistinctPoint(finish, from: hike.startCoordinate) {
						Annotation("Finish", coordinate: finish) {
							ZStack {
								Circle()
									.fill(Color.red)
									.frame(width: 24, height: 24)
									.overlay(Circle().stroke(Color.white, lineWidth: 2))
									.shadow(radius: 2)
								Image(systemName: "flag.checkered")
									.font(.system(size: 10, weight: .bold))
									.foregroundStyle(.white)
							}
						}
					}
					
					// Pinned Video Waypoint Markers
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
				
				// MARK: - Selected Video Player
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
	
	// MARK: - Video Playback
	private func playVideo(for waypoint: WaypointMarker) {
		guard let url = waypoint.localFileURL, FileManager.default.fileExists(atPath: url.path) else {
			return
		}
		self.selectedWaypoint = waypoint
		self.activePlayer = AVPlayer(url: url)
	}
	
	// MARK: - Centering Map on Hike Bounds
	private func centerMapOnRecordedHike() {
		let points = recordedPathCoordinates
		guard !points.isEmpty else { return }
		
		if points.count == 1, let singlePoint = points.first {
			cameraPosition = .region(
				MKCoordinateRegion(
					center: singlePoint,
					span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
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
		let deltaLat = max((maxLat - minLat) * 1.5, 0.008)
		let deltaLon = max((maxLon - minLon) * 1.5, 0.008)
		
		cameraPosition = .region(
			MKCoordinateRegion(
				center: center,
				span: MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
			)
		)
	}
	
	// MARK: - Distance Equality Check
	private func isDistinctPoint(_ p1: CLLocationCoordinate2D, from p2: CLLocationCoordinate2D?) -> Bool {
		guard let p2 else { return true }
		return abs(p1.latitude - p2.latitude) > 0.0001 || abs(p1.longitude - p2.longitude) > 0.0001
	}
	
	// MARK: - Helpers
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
	HikeDetailView(hike: HikeRecord(userId: "123", trailName: "Pleasure Valley", distanceMeters: 24.90, durationSeconds: 400, stepCount: 5000))
}
