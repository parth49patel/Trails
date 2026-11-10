//
//  ProfileView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import SwiftData
import FirebaseSignInWithApple

/// Displays user profile details, aggregate lifetime telemetry metrics, and local hike history.
///
/// Integrates with **SwiftData** via `@Query` to automatically observe and render all persisted
/// `HikeRecord` models chronologically, while providing Firebase account management actions
/// (sign out and account deletion).
struct ProfileView: View {
	
	// MARK: - Environment & Dependencies

	/// Global application state coordinator.
	@Environment(AppState.self) private var appState
	
	/// Presentation dismissal trigger for closing the modal sheet.
	@Environment(\.dismiss) private var dismiss
	
	/// SwiftData managed context used to execute persistent deletions.
	@Environment(\.modelContext) private var modelContext
	
	// MARK: - Persistent Queries
	
	/// Live-updating query of all completed hike records, sorted newest to oldest.
	@Query(sort: \HikeRecord.date, order: .reverse) private var hikes: [HikeRecord]
	
	// MARK: - Computed Lifetime Metrics
	
	/// Cumulative distance covered across all recorded hikes, in kilometers.
	private var totalDistanceKm: Double {
		hikes.reduce(0.0) { $0 + $1.distanceKm }
	}
	
	/// Cumulative steps logged across all recorded sessions.
	private var totalSteps: Int {
		hikes.reduce(0) { $0 + $1.stepCount }
	}
		
	var body: some View {
		NavigationStack {
			List {
				// MARK: - Lifetime Summary
				Section("Lifetime") {
					HStack {
						statCell(title: "HIKES", value: "\(hikes.count)")
						Spacer()
						statCell(title: "DISTANCE", value: String(format: "%.1f km", totalDistanceKm))
						Spacer()
						statCell(title: "STEPS", value: totalSteps.formatted())
					}
					.padding(.vertical, 6)
				}
				
				// MARK: - Local Hike History
				Section("Hike History") {
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
				}
				
				// MARK: - Account Management
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
			}
		}
	}
	
	// MARK: - Persistence Actions

	/// Removes a targeted hike record from SwiftData and commits changes to disk.
	///
	/// - Parameter hike: The `HikeRecord` entity targeted for deletion.
	private func deleteSingleHike(_ hike: HikeRecord) {
		modelContext.delete(hike)
		do {
			try modelContext.save()
		} catch {
			print("Failed to delete hike from SwiftData: \(error.localizedDescription)")
		}
	}
	
	// MARK: - UI Helpers

	/// Reusable stat counter component for high-level lifetime telemetry summary.
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
