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
	@State private var showingProfile = false
	
	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// MARK: - Header Bar
				HStack(alignment: .center) {
					VStack(alignment: .leading, spacing: 2) {
						Text("Explore Trails")
							.font(.title2.bold())
						Text("\(trails.count) nearby routes")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
					
					Button {
						showingProfile = true
					} label: {
						Image(systemName: "person.crop.circle.fill")
							.font(.system(size: 34))
							.foregroundStyle(Color.accentColor)
					}
				}
				.padding(.horizontal, 20)
				.padding(.top, 16)
				.padding(.bottom, 12)
				
				Divider()
				
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
			}
		}
		.sheet(isPresented: $showingProfile) {
			ProfileView()
				.navigationTransition(.zoom(sourceID: "reminder", in: present))
		}
	}
}

#Preview {
    BottomSheetView(
		trails: MockData.sampleTrails,
		selectedTrail: MockData.sampleTrails.first,
		onSelectTrail: { _ in },
		onStartHike: { _ in },
	)
}
