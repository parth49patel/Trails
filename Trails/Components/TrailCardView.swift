//
//  TrailCardView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI

struct TrailCardView: View {
	let trail: Trail
	let isSelected: Bool
	let onSelect: () -> Void
	let onStart: () -> Void
	
    var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .top) {
				VStack(alignment: .leading, spacing: 4) {
					Text(trail.name)
						.font(.headline)
						.foregroundStyle(.primary)
					
					Text(trail.locationName)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				Text(trail.difficulty.rawValue)
					.font(.caption2.bold())
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(difficultyColor.opacity(0.15))
					.foregroundStyle(difficultyColor)
					.clipShape(Capsule())
			}
			
			HStack(spacing: 16) {
				StatBadge(icon: "ruler", label: String(format: "%.1f km", trail.distanceKm))
				StatBadge(icon: "arrow.up.right", label: "\(trail.elevationGainMeters) m")
				StatBadge(icon: "clock", label: "\(trail.estimatedDurationMinutes) min")
			}
			
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
	
	private var difficultyColor: Color {
		switch trail.difficulty {
			case .easy: return .green
			case .moderate: return .orange
			case .hard: return .red
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
