//
//  FeatureRow.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI

/// A reusable presentation component displaying a highlighted application feature.
///
/// Pairs a system-symbol badge within a translucent circular container with a
/// dual-line title and descriptive summary, used across authentication and onboarding flows.
struct FeatureRow: View {
	
	// MARK: - Properties

	/// The SF Symbol name rendered within the circular icon container.
	let icon: String
	
	/// The primary header text describing the capability.
	let title: String
	
	/// Secondary explanatory copy providing context on how the feature operates.
	let description: String
	
	/// The foreground tint applied to the SF Symbol.
	let accent: Color
		
	var body: some View {
		HStack(alignment: .top, spacing: 14) {
			Image(systemName: icon)
				.font(.headline)
				.foregroundStyle(accent)
				.frame(width: 36, height: 36)
				.background(.ultraThinMaterial)
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.subheadline.weight(.semibold))
					.fontDesign(.rounded)
				
				Text(description)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		}
	}
}

#Preview {
	FeatureRow(
		icon: "figure.walk",
		title: "Step Telemetry",
		description: "Tracks active steps using CoreMotion coprocessor data.",
		accent: .green
	)
	.padding()
}
