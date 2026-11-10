//
//  AuthView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import FirebaseSignInWithApple

/// The gateway authentication screen for the Trails application.
///
/// Presents an introductory overview of the core telemetry and tracking capabilities
/// (distance, step count, active duration, and video memories) while facilitating
/// identity management through Firebase Authentication integrated with Sign in with Apple.
struct AuthView: View {
	var body: some View {
		VStack(spacing: 32) {
			Spacer()
			
			// MARK: - Branding & Hero Header
			VStack(spacing: 16) {
				ZStack {
					Circle()
						.fill(.ultraThinMaterial)
						.frame(width: 96, height: 96)
					
					Image(systemName: "figure.hiking")
						.font(.system(size: 44, weight: .bold))
						.foregroundStyle(.green)
				}
				
				VStack(spacing: 6) {
					Text("Trails")
						.font(.system(.largeTitle, design: .rounded, weight: .bold))
					
					Text("Your Outdoor Trail Companion")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
			
			// MARK: - Feature Highlights
			VStack(alignment: .leading, spacing: 16) {
				FeatureRow(
					icon: "figure.walk",
					title: "Steps & Distance",
					description: "Monitor distance covered and real-time step count.",
					accent: .green
				)
				
				FeatureRow(
					icon: "stopwatch.fill",
					title: "Active Time",
					description: "Accurately record your elapsed time on the trail.",
					accent: .orange
				)
				
				FeatureRow(
					icon: "video.fill",
					title: "Pinned Memories",
					description: "Capture and pin 10-second video clips to your hike.",
					accent: .blue
				)
			}
			.padding(.horizontal, 8)
			
			Spacer()
			
			// MARK: - Authentication Actions
			VStack(spacing: 12) {
				// Native Apple Sign-In flow bridged via Firebase Authentication
				FirebaseSignInWithAppleButton {
					FirebaseSignInWithAppleLabel(.signIn)
				}
				.frame(height: 50)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				
				Text("Sign in to personalize your hiking log.")
					.font(.caption2)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
			.padding(.horizontal, 24)
			.padding(.bottom, 16)
		}
		.padding()
	}
}

#Preview {
    AuthView()
}
