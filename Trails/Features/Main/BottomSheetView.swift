//
//  BottomSheetView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI

/// Presents the primary bottom sheet interface for discovering trails and initiating tracking sessions.
///
/// Serves two distinct exploration workflows:
/// - **Curated Routes:** Renders a vertically scrollable catalog of pre-mapped trails via `TrailCardView`.
/// - **Free Roam:** Quick-action button enabling unguided tracking without a predefined route boundary.
struct BottomSheetView: View {
	
	// MARK: - Properties

	/// Curated collection of nearby trails available for exploration.
	let trails: [Trail]
	
	/// The currently highlighted trail, matching map viewport selections.
	let selectedTrail: Trail?
	
	/// Callback triggered when a user taps a trail card to synchronize map camera bounds.
	let onSelectTrail: (Trail) -> Void
	
	/// Callback triggered to initiate live tracking (`nil` indicates an open Free Roam session).
	let onStartHike: (Trail?) -> Void
	
	// MARK: - State

	/// Controls the presentation of the modal lifetime profile and history sheet.
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
				// MARK: - Free Roam Action
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
				
				// MARK: - Profile Navigation
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
			onStartHike: { _ in }
		)
	}
}
