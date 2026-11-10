//
//  TrailCardView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI

/// An interactive card component presenting summary telemetry for a candidate trail.
///
/// Displays distance, estimated duration, and step count in equal-width badges.
/// When selected, the card animates an accent outline and reveals a direct call-to-action
/// button to initiate live tracking.
struct TrailCardView: View {
	
	// MARK: - Properties
	
	/// The trail entity providing telemetry metrics and geographic identifiers.
	let trail: Trail
	
	/// Indicates whether this card is currently selected by the user.
	let isSelected: Bool
	
	/// Closure invoked when the card container is tapped to toggle selection.
	let onSelect: () -> Void
	
	/// Closure invoked when the user confirms and initiates tracking on this trail.
	let onStart: () -> Void
		
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			// MARK: - Header
			VStack(alignment: .leading, spacing: 4) {
				Text(trail.name)
					.font(.headline)
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				Text(trail.locationName)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(1)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			
			// MARK: - Core Metrics Badges
			HStack(spacing: 8) {
				StatBadge(icon: "ruler", label: String(format: "%.1f km", trail.distanceKm))
					.frame(maxWidth: .infinity, alignment: .leading)
				
				StatBadge(icon: "clock", label: "\(trail.estimatedDurationMinutes) min")
					.frame(maxWidth: .infinity, alignment: .leading)
				
				StatBadge(icon: "figure.walk", label: "\(trail.estimatedSteps.formatted())")
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			// MARK: - Action Trigger
			if isSelected {
				Button(action: onStart) {
					HStack {
						Image(systemName: "figure.hiking")
						Text("Start This Hike")
							.fontWeight(.semibold)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 10)
					.background(.accent)
					.foregroundStyle(.white)
					.clipShape(RoundedRectangle(cornerRadius: 10))
				}
				.padding(.top, 4)
				.transition(.opacity.combined(with: .move(edge: .top)))
			}
		}
		.padding(14)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(.thinMaterial)
				.overlay(
					RoundedRectangle(cornerRadius: 14)
						.stroke(isSelected ? .accent : Color.clear, lineWidth: 1.5)
				)
		)
		.contentShape(Rectangle())
		.onTapGesture {
			withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
				onSelect()
			}
		}
	}
}

#Preview {
	VStack(spacing: 16) {
		// Unselected state
		TrailCardView(
			trail: MockData.sampleTrails[0],
			isSelected: false,
			onSelect: {},
			onStart: {}
		)
		
		// Selected state (shows the "Start This Hike" button)
		TrailCardView(
			trail: MockData.sampleTrails[0],
			isSelected: true,
			onSelect: {},
			onStart: {}
		)
	}
	.padding()
	.background(Color(UIColor.systemGroupedBackground))
}
