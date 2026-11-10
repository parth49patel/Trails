//
//  StatBadge.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI

/// A reusable micro-badge component pairing an SF Symbol with a concise telemetry metric.
///
/// Designed for high-density layouts such as trail cards, summary sheets, and tracking HUDs.
struct StatBadge: View {
	
	// MARK: - Properties
	
	/// The SF Symbol name displayed as the leading indicator.
	let icon: String
	
	/// The formatted telemetry value or descriptor text.
	let label: String
		
	var body: some View {
		HStack(spacing: 4) {
			Image(systemName: icon)
				.font(.caption2)
				.foregroundStyle(.secondary)
			
			Text(label)
				.font(.caption.weight(.medium))
				.foregroundStyle(.primary)
		}
	}
}

#Preview {
	HStack(spacing: 12) {
		StatBadge(icon: "ruler", label: "5.4 km")
		StatBadge(icon: "clock", label: "45 min")
		StatBadge(icon: "figure.walk", label: "7,200")
	}
	.padding()
}
