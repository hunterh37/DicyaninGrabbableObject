//
//  GloveGrabView.swift
//  GloveGrabDemo
//
//  Immersive scene: a floor, a few grabbable objects, and one rigged USDZ glove
//  hand (from DicyaninHandGlove) driven by the mock hand-tracking controller so
//  it works in the Simulator. A grabber rides along with the glove. Tap the
//  glove to toggle its grip; drag it to move it around. Grabbing near an object
//  latches it, dragging carries it, and releasing the grip runs that object's
//  drop behavior, so a single glove exercises the full GrabbableObject sequence.
//

import SwiftUI
import RealityKit
import simd
import DicyaninGrabbableObject
import DicyaninHandGlove

struct GloveGrabView: View {
    @ObservedObject private var mock = MockHandTrackingController.shared

    /// The grabber that follows the glove. Its invisible collision sphere is the
    /// tap/drag target.
    @State private var grabber = Entity()

    /// Whether the glove is currently gripping (drives the grab gesture state).
    @State private var isGripping = false

    /// Mock hand position captured at the start of a drag.
    @State private var dragStart: SIMD3<Float>?

    var body: some View {
        RealityView { content in
            let root = Entity()
            content.add(root)

            root.addChild(makeFloor())

            // Grabbable objects, each with a different drop behavior.
            root.addChild(makeCube(at: [-0.18, 1.05, -0.6]))
            root.addChild(makeBall(at: [0.0, 1.05, -0.6]))
            root.addChild(makeGem(at: [0.18, 1.05, -0.6]))

            // The rigged USDZ glove hand (right), driven by the mock controller
            // in the Simulator. Falls back to the procedural glove if the USDZ
            // can't be loaded.
            HandGloveView.addHands(to: content, configuration: .init(
                tracksLeftHand: false,
                tracksRightHand: true,
                style: .model(left: "LeftGlove", right: "RightGlove")
            ))

            // The grabber co-located with the glove. An invisible collision
            // sphere makes the whole hand tappable / draggable.
            configureGrabber(grabber)
            root.addChild(grabber)

        } update: { _ in
            grabber.setPosition(mock.rightHandPosition, relativeTo: nil)
            grabber.setOrientation(simd_quatf(angle: mock.rightHandYaw, axis: [0, 1, 0]), relativeTo: nil)
            grabber.setGrabbing(isGripping)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .targetedToAnyEntity()
                .onChanged { value in
                    let start = dragStart ?? mock.rightHandPosition
                    if dragStart == nil { dragStart = start }
                    let k: Float = 0.0025
                    mock.rightHandPosition = start + [
                        Float(value.translation.width) * k,
                        Float(-value.translation.height) * k,
                        0
                    ]
                }
                .onEnded { value in
                    let moved = hypot(value.translation.width, value.translation.height)
                    if moved < 12 { isGripping.toggle() }
                    dragStart = nil
                }
        )
    }

    // MARK: - Grabber

    private func configureGrabber(_ hand: Entity) {
        // Invisible input target so taps / drags hit the hand without occluding
        // the glove mesh.
        let target = ModelEntity(
            mesh: .generateSphere(radius: 0.06),
            materials: [UnlitMaterial(color: .init(white: 1, alpha: 0.001))]
        )
        target.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.06)]))
        target.components.set(InputTargetComponent())
        hand.addChild(target)
        hand.makeGrabber(DicyaninGrabberComponent(chirality: .right, anchorOffset: .zero, grabRadius: 0.06))
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

    private func makeBall(at p: SIMD3<Float>) -> Entity {
        let ball = ModelEntity(mesh: .generateSphere(radius: 0.045), materials: [colorMat(.systemGreen)])
        ball.setPosition(p, relativeTo: nil)
        ball.makeGrabbable(DicyaninGrabbableComponent(
            collisionShapeExtents: [0.05, 0.05, 0.05],
            followSmoothing: 0.45,
            dropBehavior: .realisticDrop
        ))
        return ball
    }

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
