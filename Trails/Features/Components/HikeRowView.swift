//
//  HikeRowView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI

/// A list row component presenting a persisted hike record.
///
/// Summarizes the session across its primary telemetry metrics: total distance,
/// active duration, pedometer step count, completion date, and an indicator badge
/// for attached video memory waypoints.
struct HikeRowView: View {
	
	// MARK: - Properties

	/// The persisted SwiftData record providing telemetry data and waypoint associations.
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
	
	// MARK: - Helper Methods

	/// Formats total elapsed seconds into a zero-padded `MM:SS` duration string.
	///
	/// - Parameter seconds: Total active time in seconds.
	/// - Returns: A formatted string representing minutes and seconds.
	private func formattedDuration(seconds: Int) -> String {
		let mins = seconds / 60
		let secs = seconds % 60
		return String(format: "%02d:%02d", mins, secs)
	}
}

#Preview {
	HikeRowView(
		hike: HikeRecord(
			userId: "preview_user",
			trailName: "Pleasure Valley Loop",
			distanceMeters: 2490.0,
			durationSeconds: 400,
			stepCount: 5000
		)
	)
	.padding()
}
