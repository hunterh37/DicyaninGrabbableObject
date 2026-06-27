//
//  ShowcaseView.swift
//  GrabbableShowcase
//
//  Builds the immersive scene: a floor, two hand grabbers driven by the mock
//  controller, and four grabbable objects each demonstrating a different
//  feature / drop behavior.
//

import SwiftUI
import RealityKit
import simd
import DicyaninGrabbableObject
import DicyaninMockHandTracking

struct ShowcaseView: View {
    @ObservedObject private var hands = MockHandTrackingController.shared
    @ObservedObject private var settings = ShowcaseSettings.shared

    @State private var leftHand = Entity()
    @State private var rightHand = Entity()

    var body: some View {
        RealityView { content in
            let root = Entity()
            content.add(root)

            root.addChild(makeFloor())

            // Two hand grabbers (small glowing spheres so you can see them).
            configureHand(leftHand, color: .white, chirality: .left)
            configureHand(rightHand, color: .white, chirality: .right)
            root.addChild(leftHand)
            root.addChild(rightHand)

            // Grabbable objects.
            root.addChild(makeSpatula(at: [-0.3, 1.1, -0.6]))
            root.addChild(makeCube(at: [-0.1, 1.1, -0.6]))
            root.addChild(makeBall(at: [0.1, 1.1, -0.6]))
            root.addChild(makeGem(at: [0.3, 1.1, -0.6]))

        } update: { content in
            // Push the latest mock hand poses into the grabber entities each frame.
            apply(hands.leftHandPosition, yaw: hands.leftHandYaw, to: leftHand)
            apply(hands.rightHandPosition, yaw: hands.rightHandYaw, to: rightHand)
            leftHand.setGrabbing(hands.isPinching)
            rightHand.setGrabbing(hands.isPinching)

            // Apply the debug-overlay toggle to every grabbable in the scene.
            content.entities.first?.setGrabDebugVisibleRecursively(settings.showDebug)
        }
    }

    // MARK: - Hands

    private func configureHand(_ hand: Entity, color: UIColor, chirality: DicyaninGrabberComponent.Chirality) {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: color.withAlphaComponent(0.7))
        mat.emissiveColor = .init(color: color)
        mat.emissiveIntensity = 0.6
        hand.components.set(ModelComponent(mesh: .generateSphere(radius: 0.03), materials: [mat]))
        hand.makeGrabber(DicyaninGrabberComponent(chirality: chirality, anchorOffset: .zero))
    }

    private func apply(_ position: SIMD3<Float>, yaw: Float, to hand: Entity) {
        hand.setPosition(position, relativeTo: nil)
        hand.setOrientation(simd_quatf(angle: yaw, axis: [0, 1, 0]), relativeTo: nil)
    }

    // MARK: - Floor

    private func makeFloor() -> Entity {
        let floor = Entity()
        let size: SIMD3<Float> = [4, 0.05, 4]
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .init(white: 0.25, alpha: 0.4))
        floor.components.set(ModelComponent(mesh: .generateBox(size: size), materials: [mat]))
        floor.components.set(CollisionComponent(shapes: [.generateBox(size: size)]))
        floor.components.set(PhysicsBodyComponent(massProperties: .default, material: nil, mode: .static))
        floor.setPosition([0, 0.5, -0.6], relativeTo: nil)
        return floor
    }

    // MARK: - Objects

    /// Orange "spatula": demonstrates hold angle, grip offset, and a grab
    /// sweet-spot on the handle. Built by the shared DemoFactory.
    private func makeSpatula(at p: SIMD3<Float>) -> Entity {
        let spatula = DemoFactory.spatula()
        spatula.setPosition(p, relativeTo: nil)
        return spatula
    }

    /// Blue cube: freezes in place when released (place-on-shelf feel).
    private func makeCube(at p: SIMD3<Float>) -> Entity {
        let cube = ModelEntity(mesh: .generateBox(size: 0.08, cornerRadius: 0.008), materials: [colorMat(.systemBlue)])
        cube.setPosition(p, relativeTo: nil)
        cube.makeGrabbable(DicyaninGrabbableComponent(
            collisionShapeExtents: [0.045, 0.045, 0.045],
            followSmoothing: 0.5,
            dropBehavior: .freezeInPlace
        ))
        return cube
    }

    /// Green ball: custom drop path — hops up, arcs forward, then physics.
    private func makeBall(at p: SIMD3<Float>) -> Entity {
        let ball = ModelEntity(mesh: .generateSphere(radius: 0.045), materials: [colorMat(.systemGreen)])
        ball.setPosition(p, relativeTo: nil)
        let path = DropPath(waypoints: [
            .init(position: [0, 0.06, 0], time: 0.18),
            .init(position: [0, 0.02, 0.12], time: 0.45)
        ], handOffToPhysics: true)
        ball.makeGrabbable(DicyaninGrabbableComponent(
            collisionShapeExtents: [0.05, 0.05, 0.05],
            followSmoothing: 0.45,
            dropBehavior: DropBehavior(mode: .customPath(path))
        ))
        return ball
    }

    /// Pink gem: fully custom release — spins and floats upward instead of falling.
    private func makeGem(at p: SIMD3<Float>) -> Entity {
        let gem = ModelEntity(mesh: .generateSphere(radius: 0.04), materials: [colorMat(.systemPink)])
        gem.setPosition(p, relativeTo: nil)
        gem.makeGrabbable(DicyaninGrabbableComponent(
            collisionShapeExtents: [0.05, 0.05, 0.05],
            followSmoothing: 0.5,
            dropBehavior: DropBehavior(mode: .custom { entity, ctx in
                var t = Transform(matrix: entity.transformMatrix(relativeTo: nil))
                t.translation = ctx.worldPosition + [0, 0.25, 0]
                t.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0]) * ctx.worldRotation
                entity.move(to: t, relativeTo: nil, duration: 1.2, timingFunction: .easeOut)
            })
        ))
        return gem
    }

    // MARK: - Helpers

    private func colorMat(_ c: UIColor) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: c)
        mat.roughness = 0.4
        mat.metallic = 0.1
        return mat
    }
}
