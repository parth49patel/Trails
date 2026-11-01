//
//  HikeDetailView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import SwiftUI
import MapKit
import AVKit

struct HikeDetailView: View {
	let hike: HikeRecord
	
	@State private var cameraPosition: MapCameraPosition = .automatic
	@State private var selectedWaypoint: WaypointMarker?
	@State private var activePlayer: AVPlayer?
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
					// MARK: - Map with Route & Waypoint Pins
				Map(position: $cameraPosition) {
					if !hike.routeCoordinates.isEmpty {
						MapPolyline(coordinates: hike.routeCoordinates)
							.stroke(
								Color.green.gradient,
								style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
							)
					}
					
					if let start = hike.routeCoordinates.first {
						Annotation("Start", coordinate: start) {
							Circle().fill(Color.green).frame(width: 14, height: 14)
								.overlay(Circle().stroke(Color.white, lineWidth: 2))
						}
					}
					
					if let end = hike.routeCoordinates.last {
						Annotation("Finish", coordinate: end) {
							Circle().fill(Color.red).frame(width: 14, height: 14)
								.overlay(Circle().stroke(Color.white, lineWidth: 2))
						}
					}
					
						// Video Memory Pins
					ForEach(hike.waypoints) { waypoint in
						Annotation(waypoint.title, coordinate: waypoint.coordinate) {
							Button {
								playVideo(for: waypoint)
							} label: {
								ZStack {
									Circle()
										.fill(Color.white)
										.frame(width: 32, height: 32)
										.shadow(radius: 4)
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
				.onAppear { fitMapToRoute() }
				
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
				
					// MARK: - Metrics
				VStack(spacing: 12) {
					HStack(spacing: 12) {
						metricTile(label: "DISTANCE", value: String(format: "%.2f km", hike.distanceKm), icon: "figure.hiking")
						metricTile(label: "DURATION", value: formatDuration(seconds: hike.durationSeconds), icon: "clock.fill")
					}
					HStack(spacing: 12) {
						metricTile(label: "ELEV GAIN", value: String(format: "+%.0f m", hike.elevationGainMeters), icon: "arrow.up.right")
						metricTile(label: "MEMORIES", value: "\(hike.waypoints.count) pinned", icon: "video.fill")
					}
				}
				.padding(.horizontal, 16)
			}
			.padding(.vertical, 16)
		}
		.navigationTitle(hike.trailName)
		.navigationBarTitleDisplayMode(.inline)
	}
	
	private func playVideo(for waypoint: WaypointMarker) {
		guard let url = waypoint.localFileURL, FileManager.default.fileExists(atPath: url.path) else {
			print("⚠️ Video file not found on disk.")
			return
		}
		self.selectedWaypoint = waypoint
		self.activePlayer = AVPlayer(url: url)
	}
	
	private func fitMapToRoute() {
		let coords = hike.routeCoordinates
		guard !coords.isEmpty else { return }
		let lats = coords.map(\.latitude), lons = coords.map(\.longitude)
		let center = CLLocationCoordinate2D(
			latitude: (lats.min()! + lats.max()!) / 2.0,
			longitude: (lons.min()! + lons.max()!) / 2.0
		)
		let span = MKCoordinateSpan(
			latitudeDelta: max((lats.max()! - lats.min()!) * 1.35, 0.005),
			longitudeDelta: max((lons.max()! - lons.min()!) * 1.35, 0.005)
		)
		cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
	}
	
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
	HikeDetailView(hike: HikeRecord(userId: "123", trailName: "Pleasure Valley", distanceMeters: 24.90, durationSeconds: 400, elevationGainMeters: 3.0, stepCount: 5000, breadcrumbCoordinates: [[0]]))
}
