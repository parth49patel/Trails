//
//  AppDelegate.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import UIKit
import FirebaseCore

/// Adapts UIKit application lifecycle events for the SwiftUI app hierarchy.
///
/// Handles early startup configuration for backend dependencies, initializing the Firebase Core
/// runtime on launch to support user authentication (Sign in with Apple) while local tracking metrics,
/// routes, and hikes remain persisted on-device via SwiftData.
class AppDelegate: NSObject, UIApplicationDelegate {
	
	// MARK: - UIApplicationDelegate

	/// Configures underlying backend services immediately following application launch.
	///
	/// - Parameters:
	///   - application: The singleton app instance.
	///   - launchOptions: A dictionary indicating the reason the app was launched (or nil).
	/// - Returns: `true` to signal successful initialization to the iOS operating system.
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		// Initialize Firebase SDK runtime for authentication services
		FirebaseApp.configure()
		return true
	}
}
