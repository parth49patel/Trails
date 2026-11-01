//
//  VideoCaptureView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-30.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A SwiftUI wrapper over `UIImagePickerController` configured for capturing short scenic video memories.
struct VideoCaptureView: UIViewControllerRepresentable {
	
	let onVideoRecorded: (URL) -> Void
	@Environment(\.dismiss) private var dismiss
	
	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		
		// Use camera on real hardware; fall back to photo library on simulator
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
	
	final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		let parent: VideoCaptureView
		
		init(_ parent: VideoCaptureView) {
			self.parent = parent
		}
		
		func imagePickerController(
			_ picker: UIImagePickerController,
			didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
		) {
			if let mediaURL = info[.mediaURL] as? URL {
				parent.onVideoRecorded(mediaURL)
			}
			parent.dismiss()
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.dismiss()
		}
	}
}
