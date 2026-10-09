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
						.fill(.accent.opacity(0.15))
						.frame(width: 96, height: 96)
					
					Image(systemName: "figure.hiking")
						.font(.system(size: 44, weight: .bold))
						.foregroundStyle(.green)
				}
				
				VStack(spacing: 6) {
					Text("Trails")
						.font(.system(.largeTitle, design: .rounded, weight: .bold))
					
					Text("Your Intelligent Outdoor Trail Companion")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
			
			// MARK: - Feature Overview
			VStack(alignment: .leading, spacing: 14) {
				FeatureRow(
					icon: "map.fill",
					title: "Live GPS & Heading",
					description: "Track your route and compass orientation on maps.",
					accent: .accent
				)
				
				FeatureRow(
					icon: "speaker.wave.2.fill",
					title: "Hands-Free Audio",
					description: "Hear automatic distance milestones while walking.",
					accent: .accent
				)
				
				FeatureRow(
					icon: "video.fill",
					title: "Scenic Waypoint Clips",
					description: "Record 10-second memories pinned to the trail.",
					accent: .accent
				)
			}
			
			Spacer()
			
			// MARK: - Sign-In Action
			VStack(spacing: 12) {
				FirebaseSignInWithAppleButton {
					FirebaseSignInWithAppleLabel(.signIn)
				}
				.frame(height: 50)
				.clipShape(RoundedRectangle(cornerRadius: 12))
				
				Text("Sign in to sync your hikes and saved trail markers.")
					.font(.caption2)
					.foregroundStyle(.tertiary)
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
