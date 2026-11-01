//
//  AppDelegate.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import UIKit
import FirebaseCore

/// Adapts UIKit application lifecycle events for the SwiftUI app hierarchy.
/// Configures Firebase on launch to support user authentication (Sign in with Apple) while local metrics and hikes remain persisted via SwiftData.
class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
	) -> Bool {
		FirebaseApp.configure()
		return true
	}
}
