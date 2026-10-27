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
	
    var body: some Scene {
        WindowGroup {
            MainView()
				.environment(appState)
				.configureFirebaseSignInWithAppleWith(firestoreUserCollectionPath: Path.Firestore.profiles)
        }
		.modelContainer(for: [HikeRecord.self])
    }
}
