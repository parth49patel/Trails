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
				.onAppear {
					exportStoreToDocuments()
				}
		}
		.modelContainer(for: [HikeRecord.self])
	}
	init() {
		print(URL.applicationSupportDirectory.path(percentEncoded: false))
	}
	private func exportStoreToDocuments() {
		let fm = FileManager.default
		
		guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
			  let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
		
			// SwiftData creates three files: .store, -wal, and -shm
		let extensions = ["default.store", "default.store-wal", "default.store-shm"]
		
		for item in extensions {
			let source = appSupport.appendingPathComponent(item)
			let destination = docs.appendingPathComponent(item)
			
			if fm.fileExists(atPath: source.path) {
				try? fm.removeItem(at: destination)
				do {
					try fm.copyItem(at: source, to: destination)
					print("✅ Copied \(item) to Documents folder.")
				} catch {
					print("⚠️ Failed copying \(item): \(error.localizedDescription)")
				}
			}
		}
	}
}
