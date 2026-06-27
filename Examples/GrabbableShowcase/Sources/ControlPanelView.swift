//
//  ControlPanelView.swift
//  GrabbableShowcase
//
//  The window you see on launch. Open the immersive space, then use the
//  mock joysticks + pinch to drive the hands in the Simulator.
//

import SwiftUI
import DicyaninMockHandTracking

struct ControlPanelView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @ObservedObject private var settings = ShowcaseSettings.shared
    @State private var immersiveOpen = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Grabbable Showcase")
                .font(.largeTitle.bold())
            Text("Open the space, drive the hands with the joysticks, and hold **Pinch** while a hand overlaps an object to grab it. Release to trigger that object's drop behavior.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)

            Button(immersiveOpen ? "Close Space" : "Enter Showcase") {
                Task {
                    if immersiveOpen {
                        await dismissImmersiveSpace()
                        immersiveOpen = false
                    } else if case .opened = await openImmersiveSpace(id: "showcase") {
                        immersiveOpen = true
                    }
                }
            }
            .font(.title3.bold())

            Toggle("Show grab debug collision areas", isOn: $settings.showDebug)
                .frame(maxWidth: 460)

            Divider().frame(maxWidth: 460)

            // The mock hand joysticks + pinch control (bound to the shared controller).
            MockHandControlView()
                .frame(maxWidth: 460)

            LegendView()
                .frame(maxWidth: 460)
        }
        .padding(32)
    }
}

private struct LegendView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's in the scene").font(.headline)
            legend(.orange, "Spatula", "hold angle + grip offset, realistic gravity drop with throw")
            legend(.blue, "Cube", "freeze in place on release")
            legend(.green, "Ball", "custom drop path: hops up, arcs forward, then physics")
            legend(.pink, "Gem", "fully custom release closure (spins + floats up)")
        }
        .font(.caption)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legend(_ c: Color, _ title: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(c).frame(width: 12, height: 12).padding(.top, 2)
            VStack(alignment: .leading) {
                Text(title).bold()
                Text(desc).foregroundStyle(.secondary)
            }
        }
    }
}
