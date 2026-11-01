//
//  BottomSheetView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI

/// Presents the bottom sheet interface for browsing curated trails and initiating hikes.
///
/// Provides a quick action to begin an unguided "Free Roam" hike or select
/// from available pre-stored trails, each displaying the 4 core metrics.
struct BottomSheetView: View {
	
	let trails: [Trail]
	let selectedTrail: Trail?
	let onSelectTrail: (Trail) -> Void
	let onStartHike: (Trail?) -> Void
	
	@State private var showProfileView = false
	
	var body: some View {
		NavigationStack {
			ScrollView {
				LazyVStack(spacing: 12) {
					// MARK: - Curated Trail Cards
					ForEach(trails) { trail in
						TrailCardView(
							trail: trail,
							isSelected: selectedTrail?.id == trail.id,
							onSelect: { onSelectTrail(trail) },
							onStart: { onStartHike(trail) }
						)
					}
				}
				.padding()
			}
			.navigationTitle("Explore Trails")
			.navigationSubtitle("\(trails.count) nearby routes")
			.toolbarTitleDisplayMode(.inline)
			.toolbar {
				// MARK: - Free Roam Action in Toolbar
				ToolbarItem(placement: .topBarLeading) {
					Button {
						onStartHike(nil)
					} label: {
						Label("Free Roam", systemImage: "figure.hiking")
							.font(.subheadline.weight(.semibold))
					}
					.buttonStyle(.borderedProminent)
					.tint(.accentColor)
					.clipShape(Capsule())
				}
				
				// MARK: - Profile Action
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						showProfileView = true
					} label: {
						Image(systemName: "person.circle.fill")
							.font(.title3)
					}
				}
			}
			.sheet(isPresented: $showProfileView) {
				ProfileView()
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
