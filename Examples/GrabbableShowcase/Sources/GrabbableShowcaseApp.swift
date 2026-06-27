//
//  GrabbableShowcaseApp.swift
//  GrabbableShowcase
//
//  Example app for DicyaninGrabbableObject. Demonstrates every feature:
//   - hold angle + grip offset (the spatula held by its handle)
//   - grab collision shape offset / grab sweet spot
//   - all four DropBehavior modes (physics throw, freeze, custom path, custom)
//   - weighty follow smoothing
//
//  Runs in the visionOS Simulator using DicyaninMockHandTracking's on-screen
//  joysticks + pinch button — no device or real hand tracking required.
//

import SwiftUI
import DicyaninGrabbableObject

@main
struct GrabbableShowcaseApp: App {

    init() {
        // Register the package's components + system once at launch.
        DicyaninGrabbable.registerComponents()
    }

    var body: some Scene {
        // Control window: joysticks to move the mock hands, a pinch toggle to grab.
        WindowGroup(id: "controls") {
            ControlPanelView()
        }
        .windowResizability(.contentSize)

        // The immersive scene full of grabbable objects.
        ImmersiveSpace(id: "showcase") {
            ShowcaseView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
