//
//  MainView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import FirebaseSignInWithApple

/// The root presentation router for the Trails application.
///
/// Observes Firebase Authentication state and local onboarding flags to resolve the top-level
/// scene hierarchy:
/// - `.loading` / `.authenticating`: Displays an indeterminate `ProgressView` spinner.
/// - `.notAuthenticated`: Routes to `AuthView` for Sign in with Apple.
/// - `.authenticated`: Directs first-time sessions through `OnboardingView` for hardware
///   permission handshakes, or mounts `ContentView` for standard navigation.
struct MainView: View {
	
	// MARK: - Dependencies & Storage

	/// Bridges authentication state from the `FirebaseSignInWithApple` environment container.
	@Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
	
	/// Persisted user default tracking whether hardware permission onboarding has completed.
	@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
		
	var body: some View {
		Group {
			switch firebaseSignInWithApple.state {
				case .loading, .authenticating:
					ProgressView()
					
				case .notAuthenticated:
					AuthView()
					
				case .authenticated:
					if !hasCompletedOnboarding {
						OnboardingView(isOnboardingCompleted: $hasCompletedOnboarding)
							.transition(.opacity)
					} else {
						ContentView()
							.transition(.opacity)
					}
			}
		}
		.animation(.default, value: hasCompletedOnboarding)
		.animation(.default, value: firebaseSignInWithApple.state)
	}
}

#Preview {
	MainView()
}
