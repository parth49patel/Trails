//
//  ContentView.swift
//  Trails
//
//  Course: SOFE4640U Mobile Application Development
//  Group:  10
//

import SwiftUI
import MapKit
import SwiftData

/// The primary map dashboard orchestrating trail exploration, live session tracking, and HUD states.
///
/// Coordinates several core UX layers:
/// - **Interactive MapKit Viewport:** Renders the user position, start anchors for nearby trails,
///   and dynamically updates with video memory waypoints pinned during an active hike.
/// - **Collapsible Bottom Sheet:** Embeds `BottomSheetView` across three presentation detents
///   (`.fraction(0.18)`, `.medium`, `.large`), enabling non-blocking background map interaction.
/// - **Tracking HUD Overlay:** Dynamically presents `HikeTrackingView` at the top of the view
///   hierarchy when a hike session transitions into an active or paused state.
struct ContentView: View {
	
	// MARK: - Dependencies & Context

	/// Global application state coordinator governing hardware managers and tracking states.
	@Environment(AppState.self) private var appState
	
	/// SwiftData managed context injected into AppState for local persistence operations.
	@Environment(\.modelContext) private var modelContext
	
	// MARK: - View State

	/// Map camera viewport targeting the Oshawa and Durham Region trail systems by default.
	@State private var cameraPosition: MapCameraPosition = .region(
		MKCoordinateRegion(
			center: CLLocationCoordinate2D(latitude: 43.8800, longitude: -78.8350),
			span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
		)
	)
	
	/// Governs whether the bottom sheet containing trail listings is presented.
	@State private var showingBottomSheet: Bool = true
	
	/// The active detent state for the collapsible bottom sheet presentation.
	@State private var selectedDetent: PresentationDetent = .fraction(0.18)
		
	var body: some View {
		ZStack(alignment: .top) {
			// MARK: - Map Viewport
			Map(position: $cameraPosition) {
				UserAnnotation()
				
				// Pre-stored Trail Start Anchors
				ForEach(appState.availableTrails) { trail in
					Annotation(trail.name, coordinate: trail.startCoordinate) {
						Circle()
							.fill(Color.accentColor)
							.frame(width: 14, height: 14)
							.overlay(Circle().stroke(Color.white, lineWidth: 2))
							.shadow(radius: 2)
							.scaleEffect(appState.selectedTrail?.id == trail.id ? 1.4 : 1.0)
					}
				}
				
				// Live Pinned Memories (Waypoints)
				ForEach(appState.recordedWaypoints) { waypoint in
					Annotation(waypoint.title, coordinate: waypoint.coordinate) {
						ZStack {
							Circle()
								.fill(Color.blue)
								.frame(width: 28, height: 28)
								.shadow(radius: 3)
							
							Image(systemName: "video.fill")
								.font(.system(size: 12, weight: .bold))
								.foregroundStyle(.white)
						}
					}
				}
			}
			.mapControls {
				MapUserLocationButton()
				MapCompass()
				MapPitchToggle()
			}
			.mapStyle(.standard(elevation: .realistic))
			.ignoresSafeArea(.keyboard)
			.onAppear {
				appState.modelContext = modelContext
				appState.locationManager.requestAuthorization()
			}
			
			// MARK: - Active Hike HUD Overlay
			if appState.isHikeActive {
				HikeTrackingView()
					.padding(.horizontal, 16)
					.padding(.top, 8)
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(10)
			}
		}
		// Restore bottom sheet when a tracking session finishes or returns to idle
		.onChange(of: appState.hikeStatus) { oldStatus, newStatus in
			if oldStatus != .idle && newStatus == .idle {
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					showingBottomSheet = true
					selectedDetent = .medium
				}
			}
		}
		// MARK: - Trail Discovery Bottom Sheet
		.sheet(isPresented: $showingBottomSheet) {
			BottomSheetView(
				trails: appState.availableTrails,
				selectedTrail: appState.selectedTrail,
				onSelectTrail: { trail in
					withAnimation {
						appState.selectedTrail = trail
						cameraPosition = .region(
							MKCoordinateRegion(
								center: trail.startCoordinate,
								span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
							)
						)
					}
				},
				onStartHike: { trail in
					appState.startHike(for: trail)
					withAnimation {
						showingBottomSheet = false
						cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)
					}
				}
			)
			.presentationDetents([.fraction(0.18), .medium, .large], selection: $selectedDetent)
			.presentationBackgroundInteraction(.enabled(upThrough: .medium))
			.presentationDragIndicator(.visible)
			.interactiveDismissDisabled()
		}
	}
}

#Preview {
	ContentView()
		.environment(AppState())
}
