//
//  DicyaninGrabbable.swift
//  DicyaninGrabbableObject
//
//  Top-level entry point: registration + ergonomic helpers so an app can wire
//  this up in two lines.
//

import Foundation
import simd
import RealityKit

public enum DicyaninGrabbable {

    /// Call once at app launch (before showing your RealityView) to register
    /// the components and system with RealityKit.
    public static func registerComponents() {
        DicyaninGrabbableComponent.registerComponent()
        DicyaninGrabberComponent.registerComponent()
        DicyaninGrabSystem.registerSystem()
    }
}

public extension Entity {

    /// Make this entity grabbable with the given configuration.
    /// Also ensures a CollisionComponent exists for the grab sweet spot.
    @discardableResult
    func makeGrabbable(_ component: DicyaninGrabbableComponent) -> Self {
        components.set(component)

        if components[CollisionComponent.self] == nil {
            let extents = component.collisionShapeExtents ?? SIMD3<Float>(repeating: 0.05)
            let shape = ShapeResource.generateBox(size: extents * 2)
                .offsetBy(translation: component.collisionShapeOffset)
            components.set(CollisionComponent(shapes: [shape], mode: .trigger, filter: .default))
        }

        // Ensure a physics body exists so release can flip to .dynamic.
        if components[PhysicsBodyComponent.self] == nil {
            var pb = PhysicsBodyComponent()
            pb.mode = .kinematic
            components.set(pb)
        }
        return self
    }

    /// Mark this entity (a hand anchor) as a grabber.
    @discardableResult
    func makeGrabber(_ component: DicyaninGrabberComponent = .init()) -> Self {
        components.set(component)
        return self
    }

    /// Update the grab gesture state for a grabber entity each frame
    /// (e.g. from a pinch detector or hand-tracking fist heuristic).
    func setGrabbing(_ grabbing: Bool) {
        guard var g = components[DicyaninGrabberComponent.self] else { return }
        g.isGrabbing = grabbing
        components.set(g)
    }

    /// `true` if this grabbable is currently held.
    var isCurrentlyGrabbed: Bool {
        components[DicyaninGrabbableComponent.self]?.isGrabbed ?? false
    }
}
