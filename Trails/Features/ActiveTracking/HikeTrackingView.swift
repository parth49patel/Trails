//
//  HikeTrackingView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI

/// A Heads-Up Display (HUD) overlay rendering active session controls and real-time telemetry.
///
/// Presents live metrics for the 4 core tracking dimensions:
/// - Active duration (timer accounting for paused intervals)
/// - Distance covered (filtered GPS accumulation)
/// - Step count (CoreMotion coprocessor stream)
/// - Video memories (pinned AVFoundation captures)
///
/// ### Architecture Note:
/// To prevent modal hierarchy window collisions where camera dismissals caused parent bottom
/// sheets to overlap active tracking controls, the camera `.fullScreenCover` is hoisted directly
/// to this view and bound through `@Bindable(appState).isShowingCamera`.
struct HikeTrackingView: View {
	
	// MARK: - Environment & State

	/// Global application state coordinator managing active telemetry streams and session state.
	@Environment(AppState.self) private var appState
	
	/// Tracks presentation state for the destructive hike completion confirmation dialog.
	@State private var showingEndConfirmation: Bool = false
		
	var body: some View {
		VStack(spacing: 10) {
			// MARK: - Primary Row (Trail Identity, Timer, Distance & Controls)
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
				
				// MARK: - Session Action Controls
				HStack(spacing: 8) {
					// Trigger 10-second AVFoundation video recording sheet
					Button {
						appState.isShowingCamera = true
					} label: {
						Image(systemName: "video.fill")
							.font(.system(size: 13, weight: .bold))
							.foregroundStyle(.white)
							.frame(width: 34, height: 34)
							.background(Color.blue.gradient)
							.clipShape(Circle())
					}
					
					// Toggle active / paused session state
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
					
					// Trigger completion confirmation dialog
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
			
			// MARK: - Secondary Telemetry Row (Steps, Waypoints, Sensor Status)
			HStack(spacing: 0) {
				telemetryItem(
					label: "STEPS",
					value: appState.formattedSteps,
					icon: "figure.walk"
				)
				
				Spacer()
				
				telemetryItem(
					label: "MEMORIES",
					value: "\(appState.recordedWaypoints.count)",
					icon: "video.fill"
				)
				
				Spacer()
				
				telemetryItem(
					label: "STATUS",
					value: appState.hikeStatus == .paused ? "Paused" : "Recording",
					icon: "record.circle"
				)
			}
			.padding(.horizontal, 8)
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
			Text("Your distance (\(appState.formattedDistance)), duration (\(appState.formattedDuration)), and \(appState.recordedWaypoints.count) pinned memories will be saved.")
		}
		.fullScreenCover(isPresented: Bindable(appState).isShowingCamera) {
			VideoCaptureView { recordedURL in
				appState.recordVideoWaypoint(sourceURL: recordedURL)
			}
		}
	}
	
	// MARK: - UI Helpers

	/// Reusable subview rendering a compact label, system icon, and monospaced telemetry value.
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
