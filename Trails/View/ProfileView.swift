//
//  ProfileView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-08.
//

import SwiftUI
import FirebaseSignInWithApple

struct ProfileView: View {
	
	@Environment(\.dismiss) private var dismiss
	
    var body: some View {
		NavigationStack {
			List {
				Section("Hiker Stats") {
					LabeledContent("Hikes Completed", value: "4")
					LabeledContent("Total Distance", value: "49.49 km")
				}
				Section {
					FirebaseSignOutWithAppleButton {
						Label("Sign Out", systemImage: "power")
							.foregroundStyle(.red)
					}
				}
				
				Section {
					FirebaseDeleteAccountWithAppleButton {
						Label("Delete Account", systemImage: "trash")
							.foregroundStyle(.red)
					}
				} footer: {
					Text("Deleting your account permanently clears your recorded trails and stats.")
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
}

#Preview {
    ProfileView()
}
