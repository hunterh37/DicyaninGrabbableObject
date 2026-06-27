//
//  DropBehaviorTests.swift
//  Covers DropBehavior, its convenience presets, DropPath/Waypoint, and
//  ReleaseContext value semantics.
//

import XCTest
import simd
import RealityKit
@testable import DicyaninGrabbableObject

final class DropBehaviorTests: XCTestCase {

    // MARK: - Defaults & presets

    func testDefaultInit() {
        let d = DropBehavior()
        if case .physics = d.mode {} else { XCTFail("expected .physics") }
        XCTAssertTrue(d.inheritVelocity)
        XCTAssertEqual(d.velocityScale, 1.0, accuracy: 1e-6)
        XCTAssertEqual(d.releaseSpin, .zero)
        XCTAssertNil(d.mass)
    }

    func testRealisticDropPreset() {
        let d = DropBehavior.realisticDrop
        XCTAssertTrue(d.inheritVelocity)
        if case .physics = d.mode {} else { XCTFail("expected .physics") }
    }

    func testFreezeInPlacePreset() {
        let d = DropBehavior.freezeInPlace
        XCTAssertFalse(d.inheritVelocity)
        if case .freeze = d.mode {} else { XCTFail("expected .freeze") }
    }

    func testCustomScaleAndSpin() {
        let d = DropBehavior(velocityScale: 2.5, releaseSpin: [0, 10, 0], mass: 0.3)
        XCTAssertEqual(d.velocityScale, 2.5, accuracy: 1e-6)
        XCTAssertEqual(d.releaseSpin, [0, 10, 0])
        XCTAssertEqual(d.mass, 0.3)
    }

    // MARK: - custom closure mode

    func testCustomModeClosureIsInvoked() {
        let exp = expectation(description: "handler called")
        let d = DropBehavior(mode: .custom { _, ctx in
            XCTAssertEqual(ctx.worldPosition, [1, 2, 3])
            exp.fulfill()
        })
        if case .custom(let handler) = d.mode {
            handler(Entity(), ReleaseContext(
                worldPosition: [1, 2, 3],
                worldRotation: .init(ix: 0, iy: 0, iz: 0, r: 1),
                linearVelocity: .zero,
                angularVelocity: .zero
            ))
        } else {
            XCTFail("expected .custom")
        }
        wait(for: [exp], timeout: 1)
    }

    // MARK: - DropPath / Waypoint

    func testWaypointDefaultRotationIsIdentity() {
        let wp = DropPath.Waypoint(position: [0, 1, 0], time: 0.5)
        XCTAssertEqual(wp.rotation.real, 1.0, accuracy: 1e-5)
        XCTAssertEqual(simd_length(wp.rotation.imag), 0.0, accuracy: 1e-5)
        XCTAssertEqual(wp.time, 0.5, accuracy: 1e-6)
    }

    func testDropPathDefaultsToHandOffToPhysics() {
        let path = DropPath(waypoints: [.init(position: .zero, time: 0)])
        XCTAssertTrue(path.handOffToPhysics)
    }

    func testDropPathHandOffCanBeDisabled() {
        let path = DropPath(waypoints: [.init(position: .zero, time: 0)], handOffToPhysics: false)
        XCTAssertFalse(path.handOffToPhysics)
    }

    func testCustomPathModeCarriesWaypoints() {
        let path = DropPath(waypoints: [
            .init(position: [0, 0, 0], time: 0),
            .init(position: [0, -0.2, 0], time: 0.3)
        ])
        let d = DropBehavior(mode: .customPath(path))
        if case .customPath(let p) = d.mode {
            XCTAssertEqual(p.waypoints.count, 2)
        } else {
            XCTFail("expected .customPath")
        }
    }

    // MARK: - ReleaseContext

    func testReleaseContextStoresAllFields() {
        let ctx = ReleaseContext(
            worldPosition: [1, 2, 3],
            worldRotation: simd_quatf(angle: .pi, axis: [0, 1, 0]),
            linearVelocity: [4, 5, 6],
            angularVelocity: [7, 8, 9]
        )
        XCTAssertEqual(ctx.worldPosition, [1, 2, 3])
        XCTAssertEqual(ctx.linearVelocity, [4, 5, 6])
        XCTAssertEqual(ctx.angularVelocity, [7, 8, 9])
        XCTAssertEqual(simd_length(ctx.worldRotation.vector), 1.0, accuracy: 1e-4)
    }
}
