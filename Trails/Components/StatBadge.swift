//
//  StatBadge.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI

struct StatBadge: View {
	let icon: String
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
	StatBadge(icon: "bell", label: "")
}
