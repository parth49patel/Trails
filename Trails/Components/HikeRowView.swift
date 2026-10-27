//
//  HikeRowView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import SwiftUI

struct HikeRowView: View {
	let hike: HikeRecord
	
	var body: some View {
		HStack(spacing: 14) {
			ZStack {
				Circle()
					.fill(Color.accentColor.opacity(0.12))
					.frame(width: 44, height: 44)
				Image(systemName: "figure.hiking")
					.font(.body.weight(.bold))
					.foregroundStyle(Color.accentColor)
			}
			
			VStack(alignment: .leading, spacing: 3) {
				Text(hike.trailName)
					.font(.subheadline.weight(.semibold))
					.lineLimit(1)
				
				HStack(spacing: 8) {
					Text(String(format: "%.2f km", hike.distanceKm))
						.font(.caption.monospacedDigit().weight(.medium))
					Text("•")
						.foregroundStyle(.secondary)
					Text(formattedDuration(seconds: hike.durationSeconds))
						.font(.caption.monospacedDigit())
						.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
			
			VStack(alignment: .trailing, spacing: 4) {
				Text(hike.date.formatted(date: .abbreviated, time: .omitted))
					.font(.caption2)
					.foregroundStyle(.secondary)
				
				// Cloud Sync Status Pill
				Image(systemName: hike.isSyncedToCloud ? "cloud.fill" : "arrow.triangle.2.circlepath")
					.font(.system(size: 11))
					.foregroundStyle(hike.isSyncedToCloud ? .secondary : Color.orange)
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
	HikeRowView(hike: HikeRecord(userId: "123", trailName: "Pleasure Valley", distanceMeters: 24.90, durationSeconds: 400, elevationGainMeters: 3.0, stepCount: 5000, breadcrumbCoordinates: [[0]]))
}
