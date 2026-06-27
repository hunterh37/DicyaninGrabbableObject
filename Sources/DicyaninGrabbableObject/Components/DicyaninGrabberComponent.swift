//
//  DicyaninGrabberComponent.swift
//  DicyaninGrabbableObject
//
//  Attach this to a hand entity (left or right). It marks the entity as
//  capable of grabbing, defines the anchor point on the hand where objects
//  attach, and tracks the active grab gesture state.
//

import Foundation
import simd
import RealityKit

/// Marks an entity (typically a hand-tracked anchor) as able to grab objects.
public struct DicyaninGrabberComponent: Component {

    public enum Chirality: Sendable { case left, right, either }

    /// Which hand this grabber represents (used for filtering / debugging).
    public var chirality: Chirality

    /// Local-space offset from the hand entity to the point objects anchor to —
    /// usually the center of the palm or between thumb and index.
    public var anchorOffset: SIMD3<Float>

    /// Radius of this hand's grab collision sphere (meters), centered on the
    /// anchor point. A larger value makes the hand "reach" further when latching:
    /// an object latches when the distance between this hand's anchor and the
    /// object's grab point is within `grabRadius + object.grabRadius`.
    public var grabRadius: Float

    /// Whether the grab gesture (e.g. pinch / fist) is currently active.
    /// Set this from your gesture / hand-tracking code each frame.
    public var isGrabbing: Bool

    /// The object currently held by this hand (managed by the system).
    public internal(set) var heldEntityID: Entity.ID?

    public init(
        chirality: Chirality = .either,
        anchorOffset: SIMD3<Float> = .zero,
        grabRadius: Float = 0.04,
        isGrabbing: Bool = false
    ) {
        self.chirality = chirality
        self.anchorOffset = anchorOffset
        self.grabRadius = grabRadius
        self.isGrabbing = isGrabbing
    }
}
