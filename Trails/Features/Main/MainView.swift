//
//  MainView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import SwiftUI
import FirebaseSignInWithApple

/// The root router view handling top-level authentication state switching and initial onboarding.
///
/// Directs authenticated users through the hardware permission onboarding on their first session,
/// navigates to `ContentView` once complete, displays `AuthView` when unauthenticated,
/// and presents a loading indicator during auth transitions.
struct MainView: View {
	
	@Environment(\.firebaseSignInWithApple) private var firebaseSignInWithApple
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
