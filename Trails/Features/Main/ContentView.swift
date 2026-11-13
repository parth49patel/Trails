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
/// - **Interactive MapKit Viewport:** Renders the user position, start/end anchors and route polylines
///   for selected trails, and dynamically updates with video memory waypoints pinned during an active hike.
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
				
				// Selected Trail Route Polyline (Start -> End)
				if let selected = appState.selectedTrail, selected.routeCoordinates.count >= 2 {
					MapPolyline(coordinates: selected.routeCoordinates)
						.stroke(
							Color.accentColor,
							style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
						)
				}
				
				// Pre-stored Trail Start Anchors
				ForEach(appState.availableTrails) { trail in
					let isSelected = appState.selectedTrail?.id == trail.id
					
					Annotation(isSelected ? "\(trail.name) (Start)" : trail.name, coordinate: trail.startCoordinate) {
						if isSelected {
							ZStack {
								Circle()
									.fill(Color.green)
									.frame(width: 26, height: 26)
									.overlay(Circle().stroke(Color.white, lineWidth: 2))
									.shadow(radius: 3)
								Image(systemName: "flag.fill")
									.font(.system(size: 11, weight: .bold))
									.foregroundStyle(.white)
							}
						} else {
							Circle()
								.fill(Color.accentColor)
								.frame(width: 14, height: 14)
								.overlay(Circle().stroke(Color.white, lineWidth: 2))
								.shadow(radius: 2)
						}
					}
				}
				
				// Selected Trail End Anchor
				if let selected = appState.selectedTrail, let endCoord = selected.endCoordinate {
					Annotation("\(selected.name) (End)", coordinate: endCoord) {
						ZStack {
							Circle()
								.fill(Color.red)
								.frame(width: 26, height: 26)
								.overlay(Circle().stroke(Color.white, lineWidth: 2))
								.shadow(radius: 3)
							Image(systemName: "flag.checkered")
								.font(.system(size: 11, weight: .bold))
								.foregroundStyle(.white)
						}
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
						centerMap(on: trail)
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
	
	// MARK: - Map Framing Helper

	/// Frames the map camera to encompass both the start and end anchors of the selected trail.
	private func centerMap(on trail: Trail) {
		let points = trail.routeCoordinates
		guard points.count >= 2 else {
			cameraPosition = .region(
				MKCoordinateRegion(
					center: trail.startCoordinate,
					span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
				)
			)
			return
		}
		
		let lats = points.map(\.latitude)
		let lons = points.map(\.longitude)
		
		guard let minLat = lats.min(), let maxLat = lats.max(),
			  let minLon = lons.min(), let maxLon = lons.max() else { return }
		
		let center = CLLocationCoordinate2D(
			latitude: (minLat + maxLat) / 2.0,
			longitude: (minLon + maxLon) / 2.0
		)
		// 1.8x span padding keeps both flags visible above the collapsed bottom sheet
		let deltaLat = max((maxLat - minLat) * 1.8, 0.015)
		let deltaLon = max((maxLon - minLon) * 1.8, 0.015)
		
		cameraPosition = .region(
			MKCoordinateRegion(
				center: center,
				span: MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLon)
			)
		)
	}
}

#Preview {
	ContentView()
		.environment(AppState())
}
