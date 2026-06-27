//
//  GrabMath.swift
//  DicyaninGrabbableObject
//
//  Pure, side-effect-free math used by DicyaninGrabSystem. Kept separate from
//  the System (which requires a live RealityKit Scene) so the core algorithms —
//  latch detection, weighty follow smoothing, and throw-velocity estimation —
//  are deterministic and unit-testable in isolation.
//

import Foundation
import simd

enum GrabMath {

    /// Two-sphere overlap test used to decide whether a grabbing hand is close
    /// enough to latch onto an object's grab point.
    ///
    /// An object latches when the distance between the hand's anchor and the
    /// object's grab point is within the *sum* of both radii.
    static func isWithinLatchRange(
        handAnchor: SIMD3<Float>,
        grabPoint: SIMD3<Float>,
        handRadius: Float,
        objectRadius: Float
    ) -> Bool {
        simd_distance(handAnchor, grabPoint) <= handRadius + objectRadius
    }

    /// Selects the index of the nearest in-range, available grabber for an
    /// object's grab point. Returns `nil` when none qualify.
    ///
    /// - Parameters:
    ///   - candidates: tuples of (hand anchor world position, hand grab radius,
    ///     whether the hand is actively grabbing and free to latch).
    ///   - grabPoint: the object's grab point in world space.
    ///   - objectRadius: the object's grab radius.
    static func nearestLatchIndex(
        candidates: [(anchor: SIMD3<Float>, radius: Float, available: Bool)],
        grabPoint: SIMD3<Float>,
        objectRadius: Float
    ) -> Int? {
        var best: (index: Int, distance: Float)?
        for (i, c) in candidates.enumerated() where c.available {
            let d = simd_distance(c.anchor, grabPoint)
            guard d <= objectRadius + c.radius else { continue }
            if best == nil || d < best!.distance {
                best = (i, d)
            }
        }
        return best?.index
    }

    /// Per-frame "weighty follow": lerp position and slerp rotation toward the
    /// target by a clamped smoothing factor. `t == 1` snaps; `t == 0` holds.
    static func smoothedPose(
        current: (position: SIMD3<Float>, rotation: simd_quatf),
        target: (position: SIMD3<Float>, rotation: simd_quatf),
        smoothing: Float
    ) -> (position: SIMD3<Float>, rotation: simd_quatf) {
        let t = simd_clamp(smoothing, 0, 1)
        let pos = simd_mix(current.position, target.position, SIMD3<Float>(repeating: t))
        let rot = simd_slerp(current.rotation, target.rotation, t)
        return (pos, rot)
    }

    /// Estimates linear (m/s) and angular (rad/s) velocity from the two most
    /// recent samples. Returns zero when there is insufficient history.
    static func estimateVelocity(_ samples: [VelocitySample]) -> (linear: SIMD3<Float>, angular: SIMD3<Float>) {
        guard samples.count >= 2 else { return (.zero, .zero) }
        let a = samples[samples.count - 2]
        let b = samples[samples.count - 1]
        let dt = Float(max(b.time - a.time, 1e-4))
        let lin = (b.position - a.position) / dt

        // Angular velocity from quaternion delta.
        let dq = b.rotation * a.rotation.inverse
        var axis = SIMD3<Float>(dq.imag)
        let len = simd_length(axis)
        var ang = SIMD3<Float>.zero
        if len > 1e-5 {
            axis /= len
            let angle = 2 * atan2(len, dq.real)
            ang = axis * (angle / dt)
        }
        return (lin, ang)
    }
}
