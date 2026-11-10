//
//  Path.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation

/// Centralized registry for persistent storage keys, remote paths, and endpoint endpoints.
///
/// Encapsulates string literals to prevent runtime typos and provide single-source-of-truth
/// references across network and database calls.
struct Path {
	
	// MARK: - Firestore Collections

	/// Collection paths within the Cloud Firestore database hierarchy.
	struct Firestore {
		/// Collection storing user profile metadata tied to Firebase Authentication UIDs.
		static let profiles = "profiles"
	}
}
