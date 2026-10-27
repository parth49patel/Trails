//
//  ProfileView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI
import SwiftData
import FirebaseSignInWithApple

struct ProfileView: View {
	
	@Environment(AppState.self) private var appState
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	@Query(sort: \HikeRecord.date, order: .reverse) private var hikes: [HikeRecord]
    
	@State private var isSyncing: Bool = false
	
	private var totalDistanceKm: Double {
		hikes.reduce(0.0) { $0 + $1.distanceKm }
	}
	
	private var totalElevationGain: Double {
		hikes.reduce(0.0) { $0 + $1.elevationGainMeters }
	}
	
	var body: some View {
		NavigationStack {
			List {
				Section("Lifetime") {
					HStack {
						statCell(title: "HIKES", value: "\(hikes.count)")
						Spacer()
						statCell(title: "DISTANCE", value: String(format: "%.1f km", totalDistanceKm))
						Spacer()
						statCell(title: "ELEVATION", value: String(format: "+%.0f m", totalElevationGain))
					}
					.padding(.vertical, 6)
				}
				
				Section {
					if hikes.isEmpty {
						VStack(spacing: 8) {
							Image(systemName: "figure.hiking")
								.font(.largeTitle)
								.foregroundStyle(.secondary)
							Text("No Hikes Recorded Yet")
								.font(.headline)
							Text("Start a hike from the map to track and save your route.")
								.font(.caption)
								.foregroundStyle(.secondary)
								.multilineTextAlignment(.center)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 24)
					} else {
						ForEach(hikes) { hike in
							NavigationLink(destination: HikeDetailView(hike: hike)) {
								HikeRowView(hike: hike)
							}
							.swipeActions(edge: .trailing, allowsFullSwipe: true) {
								Button(role: .destructive) {
									deleteSingleHike(hike)
								} label: {
									Label("Delete", systemImage: "trash.fill")
								}
							}
						}
					}
				} header: {
					HStack {
						Text("Hike History")
						Spacer()
						if isSyncing {
							ProgressView()
								.controlSize(.small)
						}
					}
				}
				
				Section("Account") {
					FirebaseSignOutWithAppleButton {
						Label("Sign Out", systemImage: "power")
							.foregroundStyle(.orange)
					}
					
					FirebaseDeleteAccountWithAppleButton {
						Label("Delete Account", systemImage: "trash")
							.foregroundStyle(.red)
					}
				}
			}
			.navigationTitle("Profile")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}
				ToolbarItem(placement: .topBarLeading) {
					Button {
						triggerSync()
					} label: {
						Image(systemName: "arrow.triangle.2.circlepath")
					}
					.disabled(isSyncing)
				}
			}
			.task {
				triggerSync()
			}
			.refreshable {
				await appState.syncWithCloud()
			}
		}
    }
	
	private func triggerSync() {
		Task {
			isSyncing = true
			await appState.syncWithCloud()
			isSyncing = false
		}
	}
	
	private func deleteSingleHike(_ hike: HikeRecord) {
		let hikeId = hike.id
		
		modelContext.delete(hike)
		try? modelContext.save()
		
		Task {
			do {
				try await HikeDataService.shared.deleteHike(id: hikeId)
			} catch {
				print("Failed to delete rempte hike: \(error.localizedDescription)")
			}
		}
	}
	
	@ViewBuilder
	private func statCell(title: String, value: String) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(title)
				.font(.caption2.weight(.bold))
				.foregroundStyle(.secondary)
			Text(value)
				.font(.system(.title3, design: .rounded, weight: .bold))
				.foregroundStyle(.primary)
		}
	}
}

#Preview {
    ProfileView()
		.environment(AppState())
}
