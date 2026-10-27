//
//  BottomSheetView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI
import MapKit

struct BottomSheetView: View {
	
	let trails: [Trail]
	let selectedTrail: Trail?
	let onSelectTrail: (Trail) -> Void
	let onStartHike: (Trail?) -> Void
	
	@Namespace private var present
	@State private var showProfileView = false
	
	var body: some View {
		NavigationStack {
				// MARK: - Curated Trail List
			ScrollView {
				LazyVStack(spacing: 12) {
						// Quick Free-Hike Banner
					Button {
						onStartHike(nil)
					} label: {
						HStack {
							Image(systemName: "figure.hiking")
								.font(.headline)
							Text("Start Free Roam Hike")
								.font(.subheadline.bold())
							Spacer()
							Image(systemName: "chevron.right")
								.font(.caption.bold())
						}
						.padding(.horizontal, 16)
						.padding(.vertical, 12)
						.background(Color.accentColor.opacity(0.12))
						.foregroundStyle(Color.accentColor)
						.clipShape(RoundedRectangle(cornerRadius: 12))
					}
					.padding(.top, 4)
					
						// Curated Trails
					ForEach(trails) { trail in
						TrailCardView(
							trail: trail,
							isSelected: selectedTrail?.id == trail.id,
							onSelect: { onSelectTrail(trail) },
							onStart: { onStartHike(trail) }
						)
					}
				}
				.padding(16)
		}
		.navigationTitle("Explore Trails")
		.navigationSubtitle("\(trails.count) nearby routes")
		.toolbarTitleDisplayMode(.inlineLarge)
		.toolbar {
			ToolbarItem(placement: .confirmationAction) {
				Button {
					showProfileView = true
				} label: {
					Image(systemName: "person.circle.fill")
				}
			}
		}
		.sheet(isPresented: $showProfileView) {
			ProfileView()
				.navigationTransition(.zoom(sourceID: "reminder", in: present))
				.interactiveDismissDisabled()
		}
	}
	}
}

#Preview {
   NavigationStack {
    	BottomSheetView(
			trails: MockData.sampleTrails,
			selectedTrail: MockData.sampleTrails.first,
			onSelectTrail: { _ in },
			onStartHike: { _ in },
		)
    }
}
