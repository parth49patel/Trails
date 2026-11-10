//
//  VideoCaptureView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A SwiftUI `UIViewControllerRepresentable` bridge wrapping UIKit's `UIImagePickerController`.
///
/// Configured specifically for capturing short scenic video memories on active trails.
/// Enforces a hard 10-second capture cap with medium video compression to balance visual
/// quality against local sandbox storage constraints. Gracefully falls back to the system
/// photo library when running inside Xcode simulator environments lacking hardware camera access.
struct VideoCaptureView: UIViewControllerRepresentable {
	
	// MARK: - Properties

	/// Closure triggered with the temporary file URL upon successful video capture.
	let onVideoRecorded: (URL) -> Void
	
	/// Presentation dismissal trigger for closing the native camera sheet.
	@Environment(\.dismiss) private var dismiss
	
	// MARK: - UIViewControllerRepresentable Lifecycle

	/// Instantiates and configures the native `UIImagePickerController` instance.
	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		
		// Use hardware camera when available; fall back to library for simulator debugging
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			picker.sourceType = .camera
			picker.mediaTypes = [UTType.movie.identifier]
			picker.cameraCaptureMode = .video
			picker.videoMaximumDuration = 10.0 // 10-second memory cap
			picker.videoQuality = .typeMedium
		} else {
			picker.sourceType = .photoLibrary
			picker.mediaTypes = [UTType.movie.identifier]
		}
		
		picker.delegate = context.coordinator
		return picker
	}
	
	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}
	
	// MARK: - Coordinator (Delegate Handling)

	/// Coordinates delegate callbacks from UIKit's `UIImagePickerController` back into SwiftUI state.
	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		let parent: VideoCaptureView
		
		init(_ parent: VideoCaptureView) {
			self.parent = parent
		}
		
		/// Invoked when the user completes a video recording or selects a video asset.
		func imagePickerController(
			_ picker: UIImagePickerController,
			didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
		) {
			if let mediaURL = info[.mediaURL] as? URL {
				parent.onVideoRecorded(mediaURL)
			}
			parent.dismiss()
		}
		
		/// Invoked when the user cancels the camera interface without recording.
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.dismiss()
		}
	}
}
