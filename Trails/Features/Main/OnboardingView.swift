//
//  OnboardingView.swift
//  Trails
//
//  Created by Parth Patel on 2026-11-01.
//

import SwiftUI
import CoreLocation
import CoreMotion
import AVFoundation

/// Minimal onboarding screen requesting necessary hardware permissions (Location, Motion, Camera, Microphone)
/// to enable real-time tracking, step counting, and video memory capture with audio.
struct OnboardingView: View {
	
	@Binding var isOnboardingCompleted: Bool
	@Environment(AppState.self) private var appState
	
	@State private var locationAuthorized: Bool = false
	@State private var motionAuthorized: Bool = false
	@State private var cameraAuthorized: Bool = false
	@State private var microphoneAuthorized: Bool = false
	
	private let pedometer = CMPedometer()
	
	private var allPermissionsGranted: Bool {
		locationAuthorized && motionAuthorized && cameraAuthorized && microphoneAuthorized
	}
	
	var body: some View {
		VStack(spacing: 28) {
			Spacer()
			
			// MARK: - Header
			VStack(spacing: 8) {
				Image(systemName: "figure.hiking")
					.font(.system(size: 52, weight: .bold))
					.foregroundStyle(Color.accentColor)
				
				Text("Welcome to Trails")
					.font(.system(.title, design: .rounded, weight: .bold))
				
				Text("We need access to your device sensors to track your routes and capture video memories.")
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 24)
			}
			
			// MARK: - Permissions Checklist
			VStack(spacing: 12) {
				permissionRow(
					icon: "location.fill",
					title: "Location Access",
					subtitle: "Records distance and anchors your route.",
					isGranted: locationAuthorized,
					action: requestLocationAccess
				)
				
				permissionRow(
					icon: "figure.walk",
					title: "Motion & Fitness",
					subtitle: "Calculates step count during your hike.",
					isGranted: motionAuthorized,
					action: requestMotionAccess
				)
				
				permissionRow(
					icon: "camera.fill",
					title: "Camera Access",
					subtitle: "Enables 10-second video memories pinned to trails.",
					isGranted: cameraAuthorized,
					action: requestCameraAccess
				)
				
				permissionRow(
					icon: "mic.fill",
					title: "Microphone Access",
					subtitle: "Captures ambient audio with your video memories.",
					isGranted: microphoneAuthorized,
					action: requestMicrophoneAccess
				)
			}
			.padding(.horizontal, 20)
			
			Spacer()
			
			// MARK: - Bottom Action
			VStack(spacing: 12) {
				Button {
					isOnboardingCompleted = true
				} label: {
					Text(allPermissionsGranted ? "Get Started" : "Continue Anyway")
						.font(.headline)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 14)
						.background(allPermissionsGranted ? Color.accentColor : Color.secondary.opacity(0.2))
						.foregroundStyle(allPermissionsGranted ? .white : .primary)
						.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
				}
				
				if !allPermissionsGranted {
					Text("You can also adjust permissions anytime in iOS Settings.")
						.font(.caption2)
						.foregroundStyle(.tertiary)
				}
			}
			.padding(.horizontal, 20)
			.padding(.bottom, 16)
		}
		.onAppear {
			checkCurrentPermissions()
		}
	}
	
	// MARK: - Subviews
	@ViewBuilder
	private func permissionRow(
		icon: String,
		title: String,
		subtitle: String,
		isGranted: Bool,
		action: @escaping () -> Void
	) -> some View {
		HStack(spacing: 14) {
			ZStack {
				Circle()
					.fill(isGranted ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.12))
					.frame(width: 42, height: 42)
				
				Image(systemName: icon)
					.font(.system(size: 17, weight: .semibold))
					.foregroundStyle(isGranted ? Color.green : Color.accentColor)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.subheadline.weight(.semibold))
				Text(subtitle)
					.font(.caption)
					.foregroundStyle(.secondary)
					.lineLimit(2)
					.fixedSize(horizontal: false, vertical: true)
			}
			
			Spacer()
			
			if isGranted {
				Image(systemName: "checkmark.circle.fill")
					.font(.title3)
					.foregroundStyle(.green)
			} else {
				Button("Allow", action: action)
					.font(.subheadline.weight(.bold))
					.buttonStyle(.borderedProminent)
					.tint(.accentColor)
					.clipShape(Capsule())
			}
		}
		.padding(12)
		.background(.thinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
	}
	
	// MARK: - Permission Handlers
	private func checkCurrentPermissions() {
		// Location
		let locStatus = appState.locationManager.authorizationStatus
		locationAuthorized = (locStatus == .authorizedWhenInUse || locStatus == .authorizedAlways)
		
		// Camera
		let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
		cameraAuthorized = (camStatus == .authorized)
		
		// Microphone
		let micStatus = AVAudioApplication.shared.recordPermission
		microphoneAuthorized = (micStatus == .granted)
		
		// Motion
		if CMPedometer.isStepCountingAvailable() {
			let motionStatus = CMPedometer.authorizationStatus()
			motionAuthorized = (motionStatus == .authorized)
		}
	}
	
	private func requestLocationAccess() {
		appState.locationManager.requestAuthorization()
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			checkCurrentPermissions()
		}
	}
	
	private func requestMotionAccess() {
		guard CMPedometer.isStepCountingAvailable() else {
			motionAuthorized = true
			return
		}
		
		pedometer.queryPedometerData(from: Date(), to: Date()) { _, _ in
			DispatchQueue.main.async {
				self.checkCurrentPermissions()
			}
		}
	}
	
	private func requestCameraAccess() {
		AVCaptureDevice.requestAccess(for: .video) { granted in
			DispatchQueue.main.async {
				self.cameraAuthorized = granted
			}
		}
	}
	
	private func requestMicrophoneAccess() {
		AVAudioApplication.requestRecordPermission { granted in
			DispatchQueue.main.async {
				self.microphoneAuthorized = granted
			}
		}
	}
}

#Preview {
	OnboardingView(isOnboardingCompleted: .constant(false))
		.environment(AppState())
}
