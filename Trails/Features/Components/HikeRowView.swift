//
//  HikeRowView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import SwiftUI

/// A list row presenting a historical hike record with its 4 core metrics:
/// distance, duration, step count, and pinned memories.
struct HikeRowView: View {
	
	let hike: HikeRecord
	
	var body: some View {
		HStack(spacing: 14) {
			// MARK: - Leading Icon
			ZStack {
				Circle()
					.fill(Color.accentColor.opacity(0.12))
					.frame(width: 44, height: 44)
				
				Image(systemName: "figure.hiking")
					.font(.body.weight(.bold))
					.foregroundStyle(Color.accentColor)
			}
			
			// MARK: - Metrics Overview
			VStack(alignment: .leading, spacing: 4) {
				Text(hike.trailName)
					.font(.subheadline.weight(.semibold))
					.lineLimit(1)
				
				HStack(spacing: 8) {
					Text(String(format: "%.2f km", hike.distanceKm))
						.font(.caption.monospacedDigit().weight(.medium))
					Divider()
					Text(formattedDuration(seconds: hike.durationSeconds))
						.font(.caption.monospacedDigit())
						.foregroundStyle(.secondary)
					Divider()
					Text("\(hike.stepCount.formatted()) steps")
						.font(.caption.monospacedDigit())
						.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
			
			// MARK: - Trailing Details
			VStack(alignment: .trailing, spacing: 4) {
				Text(hike.date.formatted(date: .abbreviated, time: .omitted))
					.font(.caption2)
					.foregroundStyle(.secondary)
				
				if !hike.waypoints.isEmpty {
					HStack(spacing: 3) {
						Image(systemName: "video.fill")
							.font(.system(size: 10))
						Text("\(hike.waypoints.count)")
							.font(.caption2.weight(.medium))
					}
					.foregroundStyle(.blue)
				}
			}
		}
		.padding(.vertical, 2)
	}
	
	private func formattedDuration(seconds: Int) -> String {
		let mins = seconds / 60
		let secs = seconds % 60
		return String(format: "%02d:%02d", mins, secs)
	}
}

#Preview {
	HikeRowView(hike: HikeRecord(userId: "123", trailName: "Pleasure Valley", distanceMeters: 24.90, durationSeconds: 400, stepCount: 5000))
}
