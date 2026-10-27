//
//  AudioService.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import Foundation
import AVFoundation

final class AudioService: NSObject {
	static let shared = AudioService()
	
	private let synthesizer = AVSpeechSynthesizer()
	private var lastAnnouncedDistanceKm: Int = 0
	
	private override init() {
		super.init()
		configureAudioSession()
	}
	
	private func configureAudioSession() {
		do {
			let session = AVAudioSession.sharedInstance()
			try session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
			try session.setActive(true)
		} catch {
			print("Failed to configure audio session: \(error.localizedDescription)")
		}
	}
	
	func speak(_ text: String) {
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
		utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95 // Slightly slower for outdoor clarity
		utterance.pitchMultiplier = 1.0
		synthesizer.speak(utterance)
	}
	
	func reset() {
		lastAnnouncedDistanceKm = 0
		if synthesizer.isSpeaking {
			synthesizer.stopSpeaking(at: .immediate)
		}
	}

	/// Checks if a distance milestone (e.g., every 500m or 1km) has been crossed
	func evaluateMilestone(distanceMeters: Double, formattedPace: String, elevationGainMeters: Double) {
		let currentKm = Int(distanceMeters / 1000.0) // Every 1,000 meters
		
		// Announce when crossing into a new full kilometer
		if currentKm > lastAnnouncedDistanceKm && currentKm > 0 {
			lastAnnouncedDistanceKm = currentKm
			
			let message = "Milestone reached. You have completed \(currentKm) kilometer\(currentKm > 1 ? "s" : ""). Current pace is \(formattedPace) per kilometer."
			speak(message)
		}
	}
}
