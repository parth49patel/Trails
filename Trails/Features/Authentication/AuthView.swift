//
//  AuthView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import SwiftUI
import FirebaseSignInWithApple

struct AuthView: View {
	var body: some View {
		VStack(spacing: 32) {
			Spacer()
			
				// MARK: - Logo & App Title
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
			
				// MARK: - Core Metrics Overview
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
			
				// MARK: - Sign-In Action
			VStack(spacing: 12) {
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
