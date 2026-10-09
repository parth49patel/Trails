//
//  FeatureRow.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI

struct FeatureRow: View {
	
	let icon: String
	let title: String
	let description: String
	let accent: Color
	
    var body: some View {
		HStack(alignment: .top, spacing: 14) {
			Image(systemName: icon)
				.font(.headline)
				.foregroundColor(accent)
				.frame(width: 36, height: 36)
				.background(accent.opacity(0.12))
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
	FeatureRow(icon: "", title: "", description: "", accent: .accentColor)
}
