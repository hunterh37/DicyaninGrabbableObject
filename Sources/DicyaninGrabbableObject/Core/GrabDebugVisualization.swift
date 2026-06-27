//
//  GrabDebugVisualization.swift
//  DicyaninGrabbableObject
//
//  Optional debug overlay for grabbable objects. When enabled, draws:
//   - a translucent green box matching the grab collision area
//     (collisionShapeOffset + collisionShapeExtents)
//   - a translucent blue sphere showing grabRadius (the latch distance)
//
//  The DicyaninGrabSystem adds/removes this overlay automatically based on the
//  component's `showDebugVisualization` flag, so you can toggle it at runtime.
//

import Foundation
import simd
import CoreGraphics
import RealityKit

#if canImport(UIKit)
import UIKit
private typealias DCColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias DCColor = NSColor
#endif

enum GrabDebug {

    /// Name used to find/remove the overlay child entity.
    static let markerName = "__DicyaninGrabDebug"

    /// Builds the debug overlay entity for a given grabbable configuration.
    static func build(for c: DicyaninGrabbableComponent) -> Entity {
        let root = Entity()
        root.name = markerName

        // Collision-area box.
        let extents = c.collisionShapeExtents ?? SIMD3<Float>(repeating: 0.05)
        let box = ModelEntity(
            mesh: .generateBox(size: extents * 2),
            materials: [translucentMaterial(r: 0.2, g: 1.0, b: 0.4, opacity: 0.28)]
        )
        box.position = c.collisionShapeOffset
        root.addChild(box)

        // Grab-radius sphere (where a hand can latch from).
        let radiusSphere = ModelEntity(
            mesh: .generateSphere(radius: c.grabRadius),
            materials: [translucentMaterial(r: 0.3, g: 0.6, b: 1.0, opacity: 0.10)]
        )
        radiusSphere.position = c.collisionShapeOffset
        root.addChild(radiusSphere)

        return root
    }

    private static func translucentMaterial(r: Float, g: Float, b: Float, opacity: Float) -> RealityKit.Material {
        let color = DCColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
        var m = PhysicallyBasedMaterial()
        m.baseColor = .init(tint: color)
        m.blending = .transparent(opacity: .init(floatLiteral: opacity))
        m.emissiveColor = .init(color: color)
        m.emissiveIntensity = 0.5
        m.faceCulling = .none
        return m
    }
}

public extension Entity {

    /// Toggle the grab debug overlay for this entity (must already be grabbable).
    func setGrabDebugVisible(_ visible: Bool) {
        guard var g = components[DicyaninGrabbableComponent.self] else { return }
        g.showDebugVisualization = visible
        components.set(g)
    }

    /// Toggle the grab debug overlay for this entity and all descendants.
    /// Handy for a single "debug mode" switch over a whole scene.
    func setGrabDebugVisibleRecursively(_ visible: Bool) {
        setGrabDebugVisible(visible)
        for child in children { child.setGrabDebugVisibleRecursively(visible) }
    }
}
