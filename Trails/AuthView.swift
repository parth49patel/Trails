//
//  AuthView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import Foundation
import AuthenticationServices
import FirebaseAuth
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
	@Published var user: User?
	@Published var errorMessage: String?
	@Published var isLoading: Bool = false
	
	init() {
		self.user = Auth.auth().currentUser
	}
	
	func handleAppleAuthorization(_ authorization: ASAuthorization) async {
		guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
			  let rawNonce = SignInWithAppleHelper.shared.currentNonce,
			  let identityToken = appleIDCredential.identityToken,
			  let idTokenString = String(data: identityToken, encoding: .utf8) else {
			self.errorMessage = "Unable to process Apple ID credentials."
			return
		}
		
		self.isLoading = true
		self.errorMessage = nil
		
		// Construct Firebase OAuth credential
		let credential = OAuthProvider.appleCredential(
			withIDToken: idTokenString,
			rawNonce: rawNonce,
			fullName: appleIDCredential.fullName
		)
		
		do {
			let authResult = try await Auth.auth().signIn(with: credential)
			self.user = authResult.user
			self.isLoading = false
			print("Successfully authenticated user: \(authResult.user.uid)")
		} catch {
			self.isLoading = false
			self.errorMessage = error.localizedDescription
			print("Firebase Apple Auth Error: \(error.localizedDescription)")
		}
	}
	
	func signOut() {
		do {
			try Auth.auth().signOut()
			self.user = nil
		} catch {
			self.errorMessage = error.localizedDescription
		}
	}
}
