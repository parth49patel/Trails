//
//  TrailCardView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI

/// A card component displaying high-level metrics for a trail option
/// and an action button to initiate the hike when selected.
struct TrailCardView: View {
	
	let trail: Trail
	let isSelected: Bool
	let onSelect: () -> Void
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
			
			// MARK: - Core Metrics Badges (Equal-Width Columns)
			HStack(spacing: 8) {
				StatBadge(icon: "ruler", label: String(format: "%.1f km", trail.distanceKm))
					.frame(maxWidth: .infinity, alignment: .leading)
				
				StatBadge(icon: "clock", label: "\(trail.estimatedDurationMinutes) min")
					.frame(maxWidth: .infinity, alignment: .leading)
				
				StatBadge(icon: "figure.walk", label: "\(trail.estimatedSteps.formatted())")
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			// MARK: - Selection Action
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
				.fill(Color(UIColor.secondarySystemGroupedBackground))
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
