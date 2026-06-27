//
//  ShowcaseSettings.swift
//  GrabbableShowcase
//
//  Shared UI state — currently just the debug-overlay toggle, shared between
//  the control window and the immersive scene.
//

import SwiftUI

@MainActor
final class ShowcaseSettings: ObservableObject {
    static let shared = ShowcaseSettings()
    @Published var showDebug = false
    private init() {}
}
