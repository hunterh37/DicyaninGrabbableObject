//
//  DicyaninGrabSystem.swift
//  DicyaninGrabbableObject
//
//  The brain. Each frame it:
//   1. Detects grab starts: a grabbing hand near a grabbable's grab point latches it.
//   2. Holds: moves held objects to the hand anchor, applying grabOffset + holdRotation,
//      with weighty smoothing, and records velocity samples for throwing.
//   3. Detects releases: when the hand stops grabbing, runs the object's DropBehavior.
//

import Foundation
import simd
import RealityKit

public struct DicyaninGrabSystem: System {

    static let grabbableQuery = EntityQuery(where: .has(DicyaninGrabbableComponent.self))
    static let grabberQuery   = EntityQuery(where: .has(DicyaninGrabberComponent.self))

    public init(scene: Scene) {}

    public func update(context: SceneUpdateContext) {
        let now = CACurrentMediaTimeShim()
        let dt = Float(max(context.deltaTime, 1.0 / 120.0))

        // Snapshot grabbers.
        var grabbers: [(entity: Entity, comp: DicyaninGrabberComponent, anchorWorld: SIMD3<Float>, rotWorld: simd_quatf)] = []
        for hand in context.entities(matching: Self.grabberQuery, updatingSystemWhen: .rendering) {
            guard let g = hand.components[DicyaninGrabberComponent.self] else { continue }
            let m = hand.transformMatrix(relativeTo: nil)
            let rot = simd_quatf(m)
            let anchorWorld = (m * SIMD4<Float>(g.anchorOffset, 1)).xyz
            grabbers.append((hand, g, anchorWorld, rot))
        }

        for object in context.entities(matching: Self.grabbableQuery, updatingSystemWhen: .rendering) {
            guard var grab = object.components[DicyaninGrabbableComponent.self] else { continue }

            if grab.isGrabbed {
                handleHeld(object: object, grab: &grab, grabbers: grabbers, now: now, dt: dt)
            } else {
                tryLatch(object: object, grab: &grab, grabbers: grabbers)
            }
            syncDebugVisualization(object: object, grab: grab)
            object.components.set(grab)
        }
    }

    // MARK: - Debug overlay

    private func syncDebugVisualization(object: Entity, grab: DicyaninGrabbableComponent) {
        let existing = object.children.first { $0.name == GrabDebug.markerName }
        if grab.showDebugVisualization {
            if existing == nil {
                object.addChild(GrabDebug.build(for: grab))
            }
        } else if let existing {
            existing.removeFromParent()
        }
    }

    // MARK: - Latching (grab start)

    private func tryLatch(
        object: Entity,
        grab: inout DicyaninGrabbableComponent,
        grabbers: [(entity: Entity, comp: DicyaninGrabberComponent, anchorWorld: SIMD3<Float>, rotWorld: simd_quatf)]
    ) {
        // Grab point in world space (entity origin + collisionShapeOffset).
        let objMatrix = object.transformMatrix(relativeTo: nil)
        let grabPointWorld = (objMatrix * SIMD4<Float>(grab.collisionShapeOffset, 1)).xyz

        // Two-sphere overlap: hand collision radius + object grab radius.
        let candidates = grabbers.map {
            (anchor: $0.anchorWorld,
             radius: $0.comp.grabRadius,
             available: $0.comp.isGrabbing && $0.comp.heldEntityID == nil)
        }
        guard let idx = GrabMath.nearestLatchIndex(
            candidates: candidates,
            grabPoint: grabPointWorld,
            objectRadius: grab.grabRadius
        ) else { return }
        let hand = grabbers[idx].entity

        grab.isGrabbed = true
        grab.grabbingHandID = hand.id
        grab.velocitySamples.removeAll(keepingCapacity: true)

        // Suspend physics so the object follows the hand kinematically.
        if var pb = object.components[PhysicsBodyComponent.self] {
            pb.mode = .kinematic
            object.components.set(pb)
        }

        // Tell the hand what it's holding.
        if var hg = hand.components[DicyaninGrabberComponent.self] {
            hg.heldEntityID = object.id
            hand.components.set(hg)
        }
    }

    // MARK: - Holding

    private func handleHeld(
        object: Entity,
        grab: inout DicyaninGrabbableComponent,
        grabbers: [(entity: Entity, comp: DicyaninGrabberComponent, anchorWorld: SIMD3<Float>, rotWorld: simd_quatf)],
        now: TimeInterval,
        dt: Float
    ) {
        guard let hand = grabbers.first(where: { $0.entity.id == grab.grabbingHandID }) else {
            // Hand vanished (tracking lost) — treat as release.
            release(object: object, grab: &grab, hand: nil)
            return
        }

        // Released the gesture?
        if !hand.comp.isGrabbing {
            release(object: object, grab: &grab, hand: hand)
            return
        }

        // Target pose: hand anchor + holdRotation, offset by grabOffset (hand-local).
        let targetRot = hand.rotWorld * grab.holdRotation
        let targetPos = hand.anchorWorld + hand.rotWorld.act(grab.grabOffset)

        // Weighty follow via per-frame lerp/slerp.
        let current = object.transformMatrix(relativeTo: nil)
        let (newPos, newRot) = GrabMath.smoothedPose(
            current: (current.columns.3.xyz, simd_quatf(current)),
            target: (targetPos, targetRot),
            smoothing: grab.followSmoothing
        )

        object.setPosition(newPos, relativeTo: nil)
        object.setOrientation(newRot, relativeTo: nil)

        // Record velocity samples (keep ~last 6 frames).
        grab.velocitySamples.append(VelocitySample(position: newPos, rotation: newRot, time: now))
        if grab.velocitySamples.count > 6 { grab.velocitySamples.removeFirst() }
    }

    // MARK: - Release

    private func release(
        object: Entity,
        grab: inout DicyaninGrabbableComponent,
        hand: (entity: Entity, comp: DicyaninGrabberComponent, anchorWorld: SIMD3<Float>, rotWorld: simd_quatf)?
    ) {
        let (linVel, angVel) = GrabMath.estimateVelocity(grab.velocitySamples)
        let m = object.transformMatrix(relativeTo: nil)
        let ctx = ReleaseContext(
            worldPosition: m.columns.3.xyz,
            worldRotation: simd_quatf(m),
            linearVelocity: linVel,
            angularVelocity: angVel
        )

        // Clear hand state.
        if let hand, var hg = hand.entity.components[DicyaninGrabberComponent.self] {
            hg.heldEntityID = nil
            hand.entity.components.set(hg)
        }

        switch grab.dropBehavior.mode {
        case .freeze:
            if var pb = object.components[PhysicsBodyComponent.self] {
                pb.mode = .static
                object.components.set(pb)
            }

        case .physics:
            activatePhysics(object: object, behavior: grab.dropBehavior, ctx: ctx)

        case .customPath(let path):
            DropPathRunner.shared.run(path, on: object, releaseContext: ctx, behavior: grab.dropBehavior)

        case .custom(let handler):
            handler(object, ctx)
        }

        grab.isGrabbed = false
        grab.grabbingHandID = nil
        grab.velocitySamples.removeAll(keepingCapacity: true)
    }

    private func activatePhysics(object: Entity, behavior: DropBehavior, ctx: ReleaseContext) {
        var pb = object.components[PhysicsBodyComponent.self] ?? PhysicsBodyComponent()
        pb.mode = .dynamic
        if let mass = behavior.mass { pb.massProperties.mass = mass }
        object.components.set(pb)

        var motion = object.components[PhysicsMotionComponent.self] ?? PhysicsMotionComponent()
        if behavior.inheritVelocity {
            motion.linearVelocity = ctx.linearVelocity * behavior.velocityScale
            motion.angularVelocity = ctx.angularVelocity + behavior.releaseSpin
        } else {
            motion.linearVelocity = .zero
            motion.angularVelocity = behavior.releaseSpin
        }
        object.components.set(motion)
    }

}

// MARK: - Helpers

@inline(__always) func CACurrentMediaTimeShim() -> TimeInterval {
    // Wrapper so the file compiles without an explicit QuartzCore import dance.
    return ProcessInfo.processInfo.systemUptime
}

extension SIMD4 where Scalar == Float {
    var xyz: SIMD3<Float> { SIMD3(x, y, z) }
}

extension simd_float4x4 {
    var xyz: SIMD3<Float> { columns.3.xyz }
}
