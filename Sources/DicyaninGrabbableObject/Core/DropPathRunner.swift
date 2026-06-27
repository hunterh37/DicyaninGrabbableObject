//
//  DropPathRunner.swift
//  DicyaninGrabbableObject
//
//  Animates an object along a hand-authored DropPath after release, then
//  optionally hands control back to physics (gravity).
//

import Foundation
import simd
import RealityKit

final class DropPathRunner: Sendable {
    static let shared = DropPathRunner()
    private init() {}

    func run(_ path: DropPath, on object: Entity, releaseContext ctx: ReleaseContext, behavior: DropBehavior) {
        guard !path.waypoints.isEmpty else { return }

        // Keep object kinematic while we drive it.
        if var pb = object.components[PhysicsBodyComponent.self] {
            pb.mode = .kinematic
            object.components.set(pb)
        }

        // Build absolute keyframes from release pose + local waypoint offsets.
        let basePos = ctx.worldPosition
        let baseRot = ctx.worldRotation

        Task { @MainActor in
            var lastTime: TimeInterval = 0
            for wp in path.waypoints.sorted(by: { $0.time < $1.time }) {
                let segment = max(wp.time - lastTime, 0.0)
                lastTime = wp.time
                let targetPos = basePos + baseRot.act(wp.position)
                let targetRot = baseRot * wp.rotation
                await Self.animate(object, to: targetPos, rot: targetRot, duration: segment)
            }
            if path.handOffToPhysics {
                var pb = object.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent()
                pb.mode = .dynamic
                object.components.set(pb)
            }
        }
    }

    @MainActor
    private static func animate(_ object: Entity, to pos: SIMD3<Float>, rot: simd_quatf, duration: TimeInterval) async {
        var t = Transform(matrix: object.transformMatrix(relativeTo: nil))
        t.translation = pos
        t.rotation = rot
        object.move(to: t, relativeTo: nil, duration: duration, timingFunction: .easeInOut)
        if duration > 0 {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        }
    }
}
