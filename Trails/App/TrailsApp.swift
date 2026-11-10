//
//  TrailsApp.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import SwiftData
import FirebaseSignInWithApple

/// Primary entry point for Trails.
///
/// Sets up the root dependency graph, configures the local-first SwiftData container,
/// and injects the global `AppState` telemetry coordinator into the environment.
@main
struct TrailsApp: App {
	
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@State private var appState = AppState()
	
	let container: ModelContainer
	
	// MARK: - Initialization
	
	init() {
		do {
			// Route storage to Documents instead of Application Support so the
			// SQLite store and WAL files remain accessible for local sandbox auditing.
			let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
			let storeURL = docsURL.appendingPathComponent("TrailsData.store")
			let configuration = ModelConfiguration(url: storeURL)
			
			self.container = try ModelContainer(for: HikeRecord.self, configurations: configuration)
		} catch {
			fatalError("Failed to initialize SwiftData container: \(error.localizedDescription)")
		}
	}
	
	// MARK: - Scene
	
	var body: some Scene {
		WindowGroup {
			MainView()
				.environment(appState)
				.configureFirebaseSignInWithAppleWith(firestoreUserCollectionPath: Path.Firestore.profiles)
				.onAppear {
					// Bridge main context so AppState can commit background hike sessions
					if appState.modelContext == nil {
						appState.modelContext = container.mainContext
					}
				}
		}
		.modelContainer(container)
	}
}
