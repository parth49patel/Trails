//
//  TrailsApp.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import SwiftUI
import SwiftData
import FirebaseSignInWithApple

@main
struct TrailsApp: App {
	
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@State private var appState = AppState()
	
	let container: ModelContainer
	
	init() {
		do {
			// Save directly in Documents so the SQLite file and WAL are visible in Finder/Files
			let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
			let storeURL = docsURL.appendingPathComponent("TrailsData.store")
			let configuration = ModelConfiguration(url: storeURL)
			self.container = try ModelContainer(for: HikeRecord.self, configurations: configuration)
		} catch {
			fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
		}
	}
	var body: some Scene {
		WindowGroup {
			MainView()
				.environment(appState)
				.configureFirebaseSignInWithAppleWith(firestoreUserCollectionPath: Path.Firestore.profiles)
				.onAppear {
					// Pass main ModelContext to AppState so it can save hikes directly
					if appState.modelContext == nil {
						appState.modelContext = container.mainContext
					}
				}
		}
		.modelContainer(container)
	}
}
