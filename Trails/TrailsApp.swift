//
//  TrailsApp.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import SwiftUI
import FirebaseSignInWithApple

@main
struct TrailsApp: App {
	
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
    var body: some Scene {
        WindowGroup {
            MainView()
				.configureFirebaseSignInWithAppleWith(firestoreUserCollectionPath: Path.Firestore.profiles)
        }
    }
}
