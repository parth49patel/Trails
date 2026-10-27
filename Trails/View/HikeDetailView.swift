//
//  HikeDetailView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import SwiftUI
import MapKit

struct HikeDetailView: View {
	let hike: HikeRecord
	
	@State private var cameraPosition: MapCameraPosition = .automatic
	
	var body: some View {
		ScrollView {
			VStack(spacing: 20) {
				// MARK: - Recorded Trail Path Map
				Map(position: $cameraPosition) {
					if !hike.routeCoordinates.isEmpty {
						// The user's recorded breadcrumb path
						MapPolyline(coordinates: hike.routeCoordinates)
							.stroke(
								Color.green.gradient,
								style: StrokeStyle(
									lineWidth: 5,
									lineCap: .round,
									lineJoin: .round
								)
							)
						
						// Start point pin
						if let start = hike.routeCoordinates.first {
							Annotation("Start", coordinate: start) {
								ZStack {
									Circle()
										.fill(Color.white)
										.frame(width: 22, height: 22)
										.shadow(radius: 3)
									Circle()
										.fill(Color.green)
										.frame(width: 14, height: 14)
									Image(systemName: "figure.walk")
										.font(.system(size: 8, weight: .bold))
										.foregroundStyle(.white)
								}
							}
						}
						
						// Finish point pin
						if let end = hike.routeCoordinates.last {
							Annotation("Finish", coordinate: end) {
								ZStack {
									Circle()
										.fill(Color.white)
										.frame(width: 22, height: 22)
										.shadow(radius: 3)
									Circle()
										.fill(Color.red)
										.frame(width: 14, height: 14)
									Image(systemName: "flag.fill")
										.font(.system(size: 8, weight: .bold))
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
				.onAppear {
					fitMapToRoute()
				}
				
				// MARK: - Hike Summary Metrics
				VStack(spacing: 12) {
					HStack(spacing: 12) {
						metricTile(label: "DISTANCE", value: String(format: "%.2f km", hike.distanceKm), icon: "figure.hiking")
						metricTile(label: "DURATION", value: formatDuration(seconds: hike.durationSeconds), icon: "clock.fill")
					}
					HStack(spacing: 12) {
						metricTile(label: "ELEV GAIN", value: String(format: "+%.0f m", hike.elevationGainMeters), icon: "arrow.up.right")
						metricTile(label: "TOTAL STEPS", value: hike.stepCount.formatted(), icon: "shoeprints.fill")
					}
				}
				.padding(.horizontal, 16)
			}
			.padding(.vertical, 16)
		}
		.navigationTitle(hike.trailName)
		.navigationBarTitleDisplayMode(.inline)
	}
	
	// MARK: - Auto-center and zoom to fit entire route
	private func fitMapToRoute() {
		let coords = hike.routeCoordinates
		guard !coords.isEmpty else { return }
		
		let latitudes = coords.map(\.latitude)
		let longitudes = coords.map(\.longitude)
		
		let minLat = latitudes.min()!
		let maxLat = latitudes.max()!
		let minLon = longitudes.min()!
		let maxLon = longitudes.max()!
		
		let center = CLLocationCoordinate2D(
			latitude: (minLat + maxLat) / 2.0,
			longitude: (minLon + maxLon) / 2.0
		)
		
		// Add 30% padding so route endpoints aren't cropped against the borders
		let span = MKCoordinateSpan(
			latitudeDelta: max((maxLat - minLat) * 1.35, 0.005),
			longitudeDelta: max((maxLon - minLon) * 1.35, 0.005)
		)
		
		cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
	}
	
	@ViewBuilder
	private func metricTile(label: String, value: String, icon: String) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(spacing: 4) {
				Image(systemName: icon)
					.font(.caption2.weight(.bold))
				Text(label)
					.font(.caption2.weight(.bold))
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
		if hours > 0 {
			return String(format: "%dh %02dm", hours, minutes)
		} else {
			return String(format: "%dm %02ds", minutes, secs)
		}
	}
}

#Preview {
	HikeDetailView(hike: HikeRecord(userId: "123", trailName: "Pleasure Valley", distanceMeters: 24.90, durationSeconds: 400, elevationGainMeters: 3.0, stepCount: 5000, breadcrumbCoordinates: [[0]]))
}
