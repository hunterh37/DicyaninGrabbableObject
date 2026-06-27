//
//  SpatulaPreviewView.swift
//  GrabbableShowcase
//
//  A standalone view that shows the spatula on its own with the grab debug
//  collision area turned ON — so you can see exactly where the grab sweet-spot
//  (green box) and latch radius (blue sphere) sit relative to the model.
//
//  Also exposed as an Xcode #Preview for quick visual iteration.
//

import SwiftUI
import RealityKit
import simd
import DicyaninGrabbableObject

struct SpatulaPreviewView: View {
    /// Slowly spins the spatula so you can inspect the debug shapes from all sides.
    @State private var spin = false

    var body: some View {
        RealityView { content in
            // The package's components/system must be registered for the debug
            // overlay to appear (the system draws it each frame).
            DicyaninGrabbable.registerComponents()

            let pivot = Entity()
            let spatula = DemoFactory.spatula(debug: true)
            pivot.addChild(spatula)
            pivot.position = [0, 1.3, -0.6]
            content.add(pivot)

            // Gentle continuous rotation.
            var spinTransform = pivot.transform
            spinTransform.rotation = simd_quatf(angle: .pi * 2, axis: [0, 1, 0])
            pivot.move(
                to: spinTransform,
                relativeTo: pivot.parent,
                duration: 12,
                timingFunction: .linear
            )
        }
        .overlay(alignment: .bottom) {
            Text("Debug overlay ON — green = grab area, blue = latch radius")
                .font(.caption)
                .padding(8)
                .background(.ultraThinMaterial, in: .capsule)
                .padding(.bottom, 24)
        }
    }
}

#Preview(immersionStyle: .mixed) {
    SpatulaPreviewView()
}
