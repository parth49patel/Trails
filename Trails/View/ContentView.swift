//
//  ContentView.swift
//  Trails
//
//  Created by Parth Patel on 2026-10-07.
//

import SwiftUI
import MapKit
import FirebaseSignInWithApple

struct ContentView: View {
	@Environment(AppState.self) private var appState
	
	@State private var cameraPosition: MapCameraPosition = .region(
		MKCoordinateRegion(
			center: CLLocationCoordinate2D(latitude: 43.8800, longitude: -78.8350),
			span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
		)
	)
	@State private var showingBottomSheet: Bool = true
	@State private var selectedDetent: PresentationDetent = .fraction(0.18)
	
	var body: some View {
		ZStack(alignment: .top) {
			Map(position: $cameraPosition) {
				UserAnnotation()
				
				ForEach(appState.availableTrails) { trail in
					Annotation(trail.name, coordinate: trail.startCoordinate) {
						Circle()
							.fill(Color.accentColor)
							.frame(width: 14, height: 14)
							.overlay(Circle().stroke(Color.white, lineWidth: 2))
							.shadow(radius: 2)
							.scaleEffect(appState.selectedTrail?.id == trail.id ? 1.4 : 1.0)
					}
					
					if appState.selectedTrail?.id == trail.id {
						MapPolyline(coordinates: trail.routeCoordinates)
							.stroke(Color.accentColor, lineWidth: 5)
					}
				}
				
				if !appState.userBreadcrumbs.isEmpty {
					MapPolyline(coordinates: appState.userBreadcrumbs)
						.stroke(Color.green, lineWidth: 5)
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
				appState.locationManager.requestAuthorization()
			}
			
			// Active Hike HUD
			if appState.isHikeActive {
				HikeTrackingView()
					.padding(.horizontal, 16)
					.padding(.top, 8)
					.transition(.move(edge: .top).combined(with: .opacity))
					.zIndex(10)
			}
		}
		// Observe hikeStatus so that ending a hike safely restores the bottom sheet
		.onChange(of: appState.hikeStatus) { oldStatus, newStatus in
			if oldStatus != .idle && newStatus == .idle {
				showingBottomSheet = true
				withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
					selectedDetent = .medium // Bring it back up to medium so it's clearly visible
				}
			}
		}
		// Persistent Exploration Sheet
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
						selectedDetent = .fraction(0.18)
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
