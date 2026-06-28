//
//  GloveGrabDemoApp.swift
//  GloveGrabDemo
//
//  Minimal example for DicyaninGrabbableObject driven by the rigged USDZ glove
//  hand from DicyaninHandGlove. In the visionOS Simulator you tap the glove to
//  toggle its grip and drag it to move it around, running the full grab,
//  carry, and drop sequence on the grabbable objects in the scene.
//

import SwiftUI
import DicyaninGrabbableObject

@main
struct GloveGrabDemoApp: App {

    init() {
        DicyaninGrabbable.registerComponents()
    }

    var body: some Scene {
        ImmersiveSpace(id: "glove") {
            GloveGrabView()
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
