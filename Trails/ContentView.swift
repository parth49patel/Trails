//
//  ContentView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import SwiftUI
import FirebaseSignInWithApple

struct ContentView: View {
    var body: some View {
        VStack {
			FirebaseSignOutWithAppleButton {
				FirebaseSignInWithAppleLabel(.signOut)
			}
			
			FirebaseDeleteAccountWithAppleButton {
				FirebaseSignInWithAppleLabel(.deleteAccount)
			}
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
