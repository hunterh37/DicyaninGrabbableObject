//
//  GrabbableComponentTests.swift
//  Covers DicyaninGrabbableComponent: defaults, custom config, runtime state,
//  and the holdAngle Euler->quaternion convenience.
//

import XCTest
import simd
@testable import DicyaninGrabbableObject

final class GrabbableComponentTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultsMatchDocumentedValues() {
        let c = DicyaninGrabbableComponent()
        XCTAssertEqual(c.grabRadius, 0.12, accuracy: 1e-6)
        XCTAssertEqual(c.followSmoothing, 0.35, accuracy: 1e-6)
        XCTAssertEqual(c.grabOffset, .zero)
        XCTAssertEqual(c.collisionShapeOffset, .zero)
        XCTAssertNil(c.collisionShapeExtents)
        XCTAssertFalse(c.showDebugVisualization)
    }

    func testDefaultDropBehaviorIsRealisticPhysics() {
        let c = DicyaninGrabbableComponent()
        if case .physics = c.dropBehavior.mode {} else {
            XCTFail("expected default .physics drop")
        }
        XCTAssertTrue(c.dropBehavior.inheritVelocity)
    }

    func testDefaultIdentityHoldRotation() {
        let c = DicyaninGrabbableComponent()
        let v = SIMD3<Float>(1, 2, 3)
        let rotated = c.holdRotation.act(v)
        XCTAssertEqual(rotated.x, v.x, accuracy: 1e-5)
        XCTAssertEqual(rotated.y, v.y, accuracy: 1e-5)
        XCTAssertEqual(rotated.z, v.z, accuracy: 1e-5)
    }

    // MARK: - Runtime state

    func testRuntimeStateStartsUnheld() {
        let c = DicyaninGrabbableComponent()
        XCTAssertFalse(c.isGrabbed)
        XCTAssertNil(c.grabbingHandID)
    }

    // MARK: - Custom configuration

    func testCustomValuesArePreserved() {
        let extents = SIMD3<Float>(0.01, 0.02, 0.03)
        let c = DicyaninGrabbableComponent(
            grabOffset: [0.1, 0, 0],
            collisionShapeOffset: [0, 0.05, 0],
            collisionShapeExtents: extents,
            grabRadius: 0.2,
            followSmoothing: 0.8,
            dropBehavior: .freezeInPlace,
            showDebugVisualization: true
        )
        XCTAssertEqual(c.grabOffset, [0.1, 0, 0])
        XCTAssertEqual(c.collisionShapeOffset, [0, 0.05, 0])
        XCTAssertEqual(c.collisionShapeExtents, extents)
        XCTAssertEqual(c.grabRadius, 0.2, accuracy: 1e-6)
        XCTAssertEqual(c.followSmoothing, 0.8, accuracy: 1e-6)
        XCTAssertTrue(c.showDebugVisualization)
        if case .freeze = c.dropBehavior.mode {} else { XCTFail("expected .freeze") }
    }

    // MARK: - holdAngle

    func testHoldAngleIsNormalized() {
        let q = DicyaninGrabbableComponent.holdAngle(pitch: 33, yaw: -71, roll: 128)
        XCTAssertEqual(simd_length(q.vector), 1.0, accuracy: 1e-4)
    }

    func testHoldAngleZeroIsIdentity() {
        let q = DicyaninGrabbableComponent.holdAngle(pitch: 0, yaw: 0, roll: 0)
        XCTAssertEqual(q.real, 1.0, accuracy: 1e-5)
        XCTAssertEqual(simd_length(q.imag), 0.0, accuracy: 1e-5)
    }

    func testHoldAnglePitch90RotatesAboutX() {
        // 90deg pitch about +X maps +Y(0,1,0) -> +Z(0,0,1).
        let q = DicyaninGrabbableComponent.holdAngle(pitch: 90, yaw: 0, roll: 0)
        let rotated = q.act(SIMD3<Float>(0, 1, 0))
        XCTAssertEqual(rotated.x, 0, accuracy: 1e-4)
        XCTAssertEqual(rotated.y, 0, accuracy: 1e-4)
        XCTAssertEqual(rotated.z, 1, accuracy: 1e-4)
    }

    func testHoldAngleYaw90RotatesAboutY() {
        // 90deg yaw about +Y maps +Z(0,0,1) -> +X(1,0,0).
        let q = DicyaninGrabbableComponent.holdAngle(pitch: 0, yaw: 90, roll: 0)
        let rotated = q.act(SIMD3<Float>(0, 0, 1))
        XCTAssertEqual(rotated.x, 1, accuracy: 1e-4)
        XCTAssertEqual(rotated.y, 0, accuracy: 1e-4)
        XCTAssertEqual(rotated.z, 0, accuracy: 1e-4)
    }
}
