//
//  DicyaninGrabbableComponent.swift
//  DicyaninGrabbableObject
//
//  Attach this to ANY entity you want the user to be able to pick up.
//  It stores the "how should this be held" data: the hold angle, where the
//  object sits relative to the hand, its grab collision shape, and what
//  happens on release.
//

import Foundation
import simd
import RealityKit

/// Makes an entity grabbable. Add this to the object you want to pick up
/// (e.g. a spatula). All "feel" tuning lives here.
public struct DicyaninGrabbableComponent: Component {

    // MARK: Hold pose

    /// The orientation the object snaps to *relative to the hand* while held.
    /// e.g. rotate a spatula so the blade points away from the palm.
    public var holdRotation: simd_quatf

    /// Position offset of the object's origin from the hand anchor point, in
    /// hand-local space. Lets you line the handle up with the fingers.
    public var grabOffset: SIMD3<Float>

    // MARK: Grab collision (where the user can grab it)

    /// Offset of the grab collision shape from the entity origin. This is the
    /// "sweet spot" the user must reach toward (e.g. the spatula handle, not the blade).
    public var collisionShapeOffset: SIMD3<Float>

    /// Half-extents of the box used to detect a grab. If `nil`, the system falls
    /// back to the entity's existing CollisionComponent.
    public var collisionShapeExtents: SIMD3<Float>?

    /// Max distance (m) a grabbing hand can be from the grab point and still latch.
    public var grabRadius: Float

    // MARK: Follow feel

    /// 0…1 smoothing factor per frame. 1 = rigidly locked to hand (most stable),
    /// lower = laggy/weighty follow. ~0.35 feels weighty-but-responsive.
    public var followSmoothing: Float

    // MARK: Release

    /// What happens when the grab gesture ends.
    public var dropBehavior: DropBehavior

    // MARK: Debug

    /// When `true`, the system overlays a translucent box showing the grab
    /// collision area (offset + extents) plus a sphere for `grabRadius`.
    /// Toggle at runtime via `entity.setGrabDebugVisible(_:)`.
    public var showDebugVisualization: Bool

    // MARK: Runtime state (managed by DicyaninGrabSystem — don't set manually)

    public internal(set) var isGrabbed: Bool = false
    /// The hand entity currently holding this object, if any.
    public internal(set) var grabbingHandID: Entity.ID?
    /// Ring buffer of recent world positions used to estimate throw velocity.
    internal var velocitySamples: [VelocitySample] = []

    public init(
        holdRotation: simd_quatf = .init(ix: 0, iy: 0, iz: 0, r: 1),
        grabOffset: SIMD3<Float> = .zero,
        collisionShapeOffset: SIMD3<Float> = .zero,
        collisionShapeExtents: SIMD3<Float>? = nil,
        grabRadius: Float = 0.12,
        followSmoothing: Float = 0.35,
        dropBehavior: DropBehavior = .realisticDrop,
        showDebugVisualization: Bool = false
    ) {
        self.holdRotation = holdRotation
        self.grabOffset = grabOffset
        self.collisionShapeOffset = collisionShapeOffset
        self.collisionShapeExtents = collisionShapeExtents
        self.grabRadius = grabRadius
        self.followSmoothing = followSmoothing
        self.dropBehavior = dropBehavior
        self.showDebugVisualization = showDebugVisualization
    }
}

/// Convenience: build a hold rotation from Euler angles (degrees).
public extension DicyaninGrabbableComponent {
    /// - Parameters use degrees, applied in Z * Y * X order.
    static func holdAngle(pitch: Float, yaw: Float, roll: Float) -> simd_quatf {
        let p = simd_quatf(angle: pitch * .pi / 180, axis: [1, 0, 0])
        let y = simd_quatf(angle: yaw   * .pi / 180, axis: [0, 1, 0])
        let r = simd_quatf(angle: roll  * .pi / 180, axis: [0, 0, 1])
        return y * p * r
    }
}

internal struct VelocitySample {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var time: TimeInterval
}
