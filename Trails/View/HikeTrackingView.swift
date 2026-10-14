//
//  HikeTrackingView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-14.
//

import SwiftUI

struct HikeTrackingView: View {
	@Environment(AppState.self) private var appState
	@State private var showingEndConfirmation: Bool = false
	
	var body: some View {
		VStack(spacing: 10) {
			// MARK: - Primary Row (Trail Name, Timer, Distance & Controls)
			HStack(spacing: 12) {
				VStack(alignment: .leading, spacing: 2) {
					HStack(spacing: 6) {
						Circle()
							.fill(appState.hikeStatus == .paused ? Color.orange : Color.green)
							.frame(width: 7, height: 7)
						
						Text(appState.selectedTrail?.name ?? "Free Roam Hike")
							.font(.caption2.weight(.bold))
							.foregroundStyle(.secondary)
							.lineLimit(1)
					}
					
					HStack(alignment: .firstTextBaseline, spacing: 8) {
						Text(appState.formattedDuration)
							.font(.system(.title3, design: .rounded, weight: .bold))
							.monospacedDigit()
						
						Text(appState.formattedDistance)
							.font(.system(.callout, design: .rounded, weight: .bold))
							.foregroundStyle(.green)
							.monospacedDigit()
					}
				}
				
				Spacer(minLength: 8)
				
				// Controls
				HStack(spacing: 8) {
					Button {
						withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
							if appState.hikeStatus == .active {
								appState.pauseHike()
							} else {
								appState.resumeHike()
							}
						}
					} label: {
						Image(systemName: appState.hikeStatus == .paused ? "play.fill" : "pause.fill")
							.font(.system(size: 13, weight: .bold))
							.foregroundStyle(.white)
							.frame(width: 34, height: 34)
							.background(
								appState.hikeStatus == .paused
									? Color.blue.gradient
									: Color.orange.gradient
							)
							.clipShape(Circle())
					}
					
					Button {
						showingEndConfirmation = true
					} label: {
						Image(systemName: "stop.fill")
							.font(.system(size: 13, weight: .bold))
							.foregroundStyle(.white)
							.frame(width: 34, height: 34)
							.background(Color.red.gradient)
							.clipShape(Circle())
					}
				}
			}
			
			Divider()
				.background(Color.white.opacity(0.15))
			
			// MARK: - Secondary Environmental & Sensor Telemetry
			HStack(spacing: 0) {
				// Pace
				telemetryItem(
					label: "PACE",
					value: appState.formattedPace,
					icon: "speedometer"
				)
				
				Spacer()
				
				// Current Altitude
				telemetryItem(
					label: "ELEV",
					value: appState.formattedAltitude,
					icon: "mountain.2.fill"
				)
				
				Spacer()
				
				// Elevation Gain
				telemetryItem(
					label: "GAIN",
					value: appState.formattedElevationGain,
					icon: "arrow.up.right"
				)
				
				Spacer()
				
				// Steps
				telemetryItem(
					label: "STEPS",
					value: appState.formattedSteps,
					icon: "shoeprints.fill"
				)
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.background(.ultraThickMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
		.overlay(
			RoundedRectangle(cornerRadius: 22, style: .continuous)
				.stroke(Color.white.opacity(0.25), lineWidth: 1)
		)
		.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
		.confirmationDialog(
			"Finish this hike?",
			isPresented: $showingEndConfirmation,
			titleVisibility: .visible
		) {
			Button("End & Save Hike", role: .destructive) {
				appState.endAndSaveHike()
		   }
		   Button("Resume", role: .cancel) { }
		} message: {
		   Text("Your recorded path, distance (\(appState.formattedDistance)), and duration will be finalized.")
		}
	}
	
	// Sub-component for individual sensor readouts
	@ViewBuilder
	private func telemetryItem(label: String, value: String, icon: String) -> some View {
		VStack(spacing: 2) {
			HStack(spacing: 3) {
				Image(systemName: icon)
					.font(.system(size: 9, weight: .bold))
				Text(label)
					.font(.system(size: 9, weight: .bold))
			}
			.foregroundStyle(.secondary)
			
			Text(value)
				.font(.system(.caption, design: .rounded, weight: .semibold))
				.monospacedDigit()
				.foregroundStyle(.primary)
		}
	}
}

#Preview {
    HikeTrackingView()
		.environment(AppState())
}
