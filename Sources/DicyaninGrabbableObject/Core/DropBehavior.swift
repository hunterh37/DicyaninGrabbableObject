//
//  DropBehavior.swift
//  DicyaninGrabbableObject
//
//  Describes what happens to a grabbable object the moment the user
//  releases the grab gesture. This is the "release / physics activates /
//  customizable drop path" part of the system.
//

import Foundation
import simd
import RealityKit

/// Defines how a grabbable object behaves the instant it is released.
public struct DropBehavior: Sendable {

    /// The release strategy.
    public enum Mode: Sendable {
        /// Re-enable RealityKit physics so the object falls under gravity.
        /// The most "realistic" option — the spatula leaves your hand and drops.
        case physics

        /// Keep the object exactly where it was released (no gravity, no motion).
        /// Useful for placing objects on shelves / surfaces.
        case freeze

        /// Drive the object along a custom, hand-authored path of local-space
        /// waypoints before (optionally) handing control back to physics.
        case customPath(DropPath)

        /// Fully custom: you receive the entity + release state and do whatever.
        case custom(@Sendable (Entity, ReleaseContext) -> Void)
    }

    public var mode: Mode

    /// If `true`, the hand's velocity at the moment of release is transferred to
    /// the object so a "throw" feels natural. Only applies to `.physics`.
    public var inheritVelocity: Bool

    /// Scales the inherited velocity. 1.0 = 1:1, >1 exaggerates throws.
    public var velocityScale: Float

    /// Angular velocity (spin) applied on release, in radians/sec. Only `.physics`.
    public var releaseSpin: SIMD3<Float>

    /// Physics mass override applied when re-enabling physics (kg). `nil` keeps existing.
    public var mass: Float?

    public init(
        mode: Mode = .physics,
        inheritVelocity: Bool = true,
        velocityScale: Float = 1.0,
        releaseSpin: SIMD3<Float> = .zero,
        mass: Float? = nil
    ) {
        self.mode = mode
        self.inheritVelocity = inheritVelocity
        self.velocityScale = velocityScale
        self.releaseSpin = releaseSpin
        self.mass = mass
    }

    /// Convenience: realistic gravity drop with throw-velocity inheritance.
    public static let realisticDrop = DropBehavior(mode: .physics, inheritVelocity: true)

    /// Convenience: object hangs in space where released.
    public static let freezeInPlace = DropBehavior(mode: .freeze, inheritVelocity: false)
}

/// A hand-authored drop trajectory in the object's local space at release time.
public struct DropPath: Sendable {
    public struct Waypoint: Sendable {
        public var position: SIMD3<Float>
        public var rotation: simd_quatf
        /// Seconds from release at which the object should reach this waypoint.
        public var time: TimeInterval
        public init(position: SIMD3<Float>, rotation: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1), time: TimeInterval) {
            self.position = position
            self.rotation = rotation
            self.time = time
        }
    }

    public var waypoints: [Waypoint]
    /// After the path completes, hand off to physics (gravity) instead of freezing.
    public var handOffToPhysics: Bool

    public init(waypoints: [Waypoint], handOffToPhysics: Bool = true) {
        self.waypoints = waypoints
        self.handOffToPhysics = handOffToPhysics
    }
}

/// Snapshot of the object/hand state at the moment of release.
public struct ReleaseContext: Sendable {
    public var worldPosition: SIMD3<Float>
    public var worldRotation: simd_quatf
    public var linearVelocity: SIMD3<Float>
    public var angularVelocity: SIMD3<Float>
    public init(
        worldPosition: SIMD3<Float>,
        worldRotation: simd_quatf,
        linearVelocity: SIMD3<Float>,
        angularVelocity: SIMD3<Float>
    ) {
        self.worldPosition = worldPosition
        self.worldRotation = worldRotation
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
    }
}
