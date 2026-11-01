//
//  AudioService.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-15.
//

import Foundation
import AVFoundation

/// Handles speech synthesis cues for session lifecycle events and kilometer milestones.
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
			try session.setCategory(
				.playback,
				mode: .voicePrompt,
				options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
			)
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
	
	/// Evaluates if a distance milestone (every 1 km) has been reached.
	func evaluateMilestone(distanceMeters: Double) {
		let currentKm = Int(distanceMeters / 1000.0)
		
		if currentKm > lastAnnouncedDistanceKm && currentKm > 0 {
			lastAnnouncedDistanceKm = currentKm
			
			let unit = currentKm == 1 ? "kilometer" : "kilometers"
			let message = "Milestone reached. You have completed \(currentKm) \(unit)."
			speak(message)
		}
	}
}
