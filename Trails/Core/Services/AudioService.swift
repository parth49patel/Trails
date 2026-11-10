//
//  AudioService.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import Foundation
import AVFoundation

/// Singleton service managing real-time spoken audio feedback during hiking sessions.
///
/// Integrates `AVSpeechSynthesizer` and configures `AVAudioSession` with `.voicePrompt`
/// and `.duckOthers` to announce pacing updates and kilometer milestones over background
/// audio without interrupting navigation or music playback.
final class AudioService: NSObject {
	
	// MARK: - Singleton Instance

	/// Global shared access point for audio telemetry announcements.
	static let shared = AudioService()
	
	// MARK: - Private Properties

	/// The core speech synthesis engine driving vocal announcements.
	private let synthesizer = AVSpeechSynthesizer()
	
	/// Tracks the latest integer kilometer milestone announced to prevent duplicate prompts.
	private var lastAnnouncedDistanceKm: Int = 0
	
	// MARK: - Initialization & Hardware Configuration

	/// Initializes the speech synthesizer and configures system audio routing.
	private override init() {
		super.init()
		configureAudioSession()
	}
	
	/// Sets up the device audio session category and mixing options.
	///
	/// Non-obvious Engineering Logic:
	/// - `.voicePrompt` optimizes vocal frequency curves through headphones and phone speakers.
	/// - `.duckOthers` temporarily attenuates background music or podcast volume while speaking.
	/// - `.interruptSpokenAudioAndMixWithOthers` ensures spoken prompts do not terminate third-party media apps.
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
	
	// MARK: - Speech Synthesis Actions

	/// Synthesizes and speaks a text prompt using naturalized vocal pacing.
	///
	/// - Parameter text: The string transcript to synthesize.
	func speak(_ text: String) {
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
		
		// Slightly reduced rate (0.95x) ensures speech remains intelligible in windy outdoor environments
		utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
		utterance.pitchMultiplier = 1.0
		synthesizer.speak(utterance)
	}
	
	/// Resets milestone tracking state and immediately stops any ongoing speech synthesis.
	func reset() {
		lastAnnouncedDistanceKm = 0
		if synthesizer.isSpeaking {
			synthesizer.stopSpeaking(at: .immediate)
		}
	}
	
	// MARK: - Milestone Evaluation

	/// Evaluates accumulated session distance and triggers an announcement upon each 1 km increment.
	///
	/// - Parameter distanceMeters: The total accumulated distance in meters from `LocationManager`.
	func evaluateMilestone(distanceMeters: Double) {
		let currentKm = Int(distanceMeters / 1000.0)
		
		// Announce solely when crossing into a new integer kilometer boundary
		if currentKm > lastAnnouncedDistanceKm && currentKm > 0 {
			lastAnnouncedDistanceKm = currentKm
			
			let unit = currentKm == 1 ? "kilometer" : "kilometers"
			let message = "Milestone reached. You have completed \(currentKm) \(unit)."
			speak(message)
		}
	}
}
