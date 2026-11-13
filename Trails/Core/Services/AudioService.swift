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
/// Integrates `AVSpeechSynthesizer` and configures `AVAudioSession` off the main thread
/// using `.voicePrompt` and `.duckOthers` to announce session lifecycle transitions and
/// kilometer milestones without blocking UI rendering.
final class AudioService: NSObject, @unchecked Sendable {
	
	// MARK: - Singleton Instance

	/// Global shared access point for audio telemetry announcements.
	static let shared = AudioService()
	
	// MARK: - Private Properties

	/// The core speech synthesis engine driving vocal announcements.
	private let synthesizer = AVSpeechSynthesizer()
	
	/// Dedicated background queue preventing synchronous AVAudioSession IPC calls from blocking the Main Thread.
	private let audioQueue = DispatchQueue(label: "com.trails.audioSessionQueue", qos: .userInitiated)
	
	/// Tracks the latest integer kilometer milestone announced to prevent duplicate prompts.
	private var lastAnnouncedDistanceKm: Int = 0
	
	// MARK: - Initialization & Hardware Configuration
	
	private override init() {
		super.init()
		audioQueue.async { [weak self] in
			self?.configureAudioSessionSync()
		}
	}
	
	/// Sets up the device audio session category and mixing options synchronously on a background queue.
	///
	/// Non-obvious Engineering Logic:
	/// - `.voicePrompt` optimizes vocal frequency curves through headphones and phone speakers.
	/// - `.duckOthers` temporarily attenuates background music or podcast volume while speaking.
	/// - `.interruptSpokenAudioAndMixWithOthers` ensures spoken prompts do not terminate third-party media apps.
	/// - Executed on `audioQueue` to avoid Main Thread Checker IPC latency warnings.
	private func configureAudioSessionSync() {
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
	/// - Parameters:
	///   - text: The string transcript to synthesize.
	///   - interruptCurrent: Stops any currently speaking utterance so immediate state cues play without delay.
	func speak(_ text: String, interruptCurrent: Bool = true) {
		audioQueue.async { [weak self] in
			guard let self else { return }
			
			// Configure hardware audio session off the main thread
			self.configureAudioSessionSync()
			
			if interruptCurrent && self.synthesizer.isSpeaking {
				self.synthesizer.stopSpeaking(at: .immediate)
			}
			
			let utterance = AVSpeechUtterance(string: text)
			utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
			utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
			utterance.pitchMultiplier = 1.0
			
			self.synthesizer.speak(utterance)
		}
	}
	
	/// Resets milestone tracking state.
	/// - Parameter interruptSpeech: Pass `false` when ending a hike so completion cues finish speaking.
	func reset(interruptSpeech: Bool = true) {
		lastAnnouncedDistanceKm = 0
		if interruptSpeech {
			audioQueue.async { [weak self] in
				guard let self else { return }
				if self.synthesizer.isSpeaking {
					self.synthesizer.stopSpeaking(at: .immediate)
				}
			}
		}
	}
	
	// MARK: - Milestone Evaluation

	/// Evaluates accumulated session distance and triggers an announcement upon each 1 km increment.
	///
	/// - Parameter distanceMeters: The total accumulated distance in meters from `LocationManager`.
	func evaluateMilestone(distanceMeters: Double) {
		let currentKm = Int(distanceMeters / 1000.0)
		
		if currentKm > lastAnnouncedDistanceKm && currentKm > 0 {
			lastAnnouncedDistanceKm = currentKm
			
			let unit = currentKm == 1 ? "kilometer" : "kilometers"
			let message = "Milestone reached. You have completed \(currentKm) \(unit)."
			speak(message, interruptCurrent: false)
		}
	}
}
