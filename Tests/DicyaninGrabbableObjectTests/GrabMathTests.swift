//
//  GrabMathTests.swift
//  Exercises the pure core algorithms that the System delegates to:
//  latch detection, nearest-grabber selection, follow smoothing, and
//  throw-velocity estimation.
//

import XCTest
import simd
@testable import DicyaninGrabbableObject

final class GrabMathTests: XCTestCase {

    // MARK: - isWithinLatchRange (two-sphere overlap)

    func testLatchInRangeWhenSpheresOverlap() {
        // distance 0.1, radii sum 0.04 + 0.12 = 0.16 -> overlaps
        XCTAssertTrue(GrabMath.isWithinLatchRange(
            handAnchor: [0, 0, 0],
            grabPoint: [0.1, 0, 0],
            handRadius: 0.04,
            objectRadius: 0.12
        ))
    }

    func testLatchOutOfRangeWhenSpheresDoNotOverlap() {
        // distance 0.2 > 0.16
        XCTAssertFalse(GrabMath.isWithinLatchRange(
            handAnchor: [0, 0, 0],
            grabPoint: [0.2, 0, 0],
            handRadius: 0.04,
            objectRadius: 0.12
        ))
    }

    func testLatchInclusiveAtExactBoundary() {
        // distance exactly equals radii sum -> inclusive, should latch
        XCTAssertTrue(GrabMath.isWithinLatchRange(
            handAnchor: [0, 0, 0],
            grabPoint: [0.16, 0, 0],
            handRadius: 0.04,
            objectRadius: 0.12
        ))
    }

    func testLatchUsesEuclideanDistanceAcrossAxes() {
        // 3-4-5 style: distance = 0.05, radii sum = 0.07 -> clearly in range,
        // proving all axes contribute to the Euclidean distance.
        XCTAssertTrue(GrabMath.isWithinLatchRange(
            handAnchor: [0, 0, 0],
            grabPoint: [0.03, 0.04, 0],
            handRadius: 0.03,
            objectRadius: 0.04
        ))
        // ...and just out of range when the sum is below that distance.
        XCTAssertFalse(GrabMath.isWithinLatchRange(
            handAnchor: [0, 0, 0],
            grabPoint: [0.03, 0.04, 0],
            handRadius: 0.02,
            objectRadius: 0.02
        ))
    }

    // MARK: - nearestLatchIndex (candidate selection)

    func testNearestLatchPicksClosestInRange() {
        let candidates: [(anchor: SIMD3<Float>, radius: Float, available: Bool)] = [
            (anchor: [0.10, 0, 0], radius: 0.04, available: true),
            (anchor: [0.03, 0, 0], radius: 0.04, available: true), // closest
            (anchor: [0.08, 0, 0], radius: 0.04, available: true)
        ]
        let idx = GrabMath.nearestLatchIndex(candidates: candidates, grabPoint: [0, 0, 0], objectRadius: 0.12)
        XCTAssertEqual(idx, 1)
    }

    func testNearestLatchIgnoresUnavailableHands() {
        let candidates: [(anchor: SIMD3<Float>, radius: Float, available: Bool)] = [
            (anchor: [0.01, 0, 0], radius: 0.04, available: false), // closest but busy/not grabbing
            (anchor: [0.09, 0, 0], radius: 0.04, available: true)
        ]
        let idx = GrabMath.nearestLatchIndex(candidates: candidates, grabPoint: [0, 0, 0], objectRadius: 0.12)
        XCTAssertEqual(idx, 1)
    }

    func testNearestLatchReturnsNilWhenAllOutOfRange() {
        let candidates: [(anchor: SIMD3<Float>, radius: Float, available: Bool)] = [
            (anchor: [1, 0, 0], radius: 0.04, available: true),
            (anchor: [0, 2, 0], radius: 0.04, available: true)
        ]
        XCTAssertNil(GrabMath.nearestLatchIndex(candidates: candidates, grabPoint: [0, 0, 0], objectRadius: 0.12))
    }

    func testNearestLatchReturnsNilForEmptyCandidates() {
        XCTAssertNil(GrabMath.nearestLatchIndex(candidates: [], grabPoint: [0, 0, 0], objectRadius: 0.12))
    }

    // MARK: - smoothedPose (weighty follow)

    func testSmoothingOfOneSnapsToTarget() {
        let result = GrabMath.smoothedPose(
            current: ([0, 0, 0], simd_quatf(angle: 0, axis: [0, 1, 0])),
            target: ([1, 2, 3], simd_quatf(angle: .pi / 2, axis: [0, 1, 0])),
            smoothing: 1.0
        )
        XCTAssertEqual(result.position.x, 1, accuracy: 1e-5)
        XCTAssertEqual(result.position.y, 2, accuracy: 1e-5)
        XCTAssertEqual(result.position.z, 3, accuracy: 1e-5)
    }

    func testSmoothingOfZeroHoldsCurrent() {
        let result = GrabMath.smoothedPose(
            current: ([5, 6, 7], .init(ix: 0, iy: 0, iz: 0, r: 1)),
            target: ([1, 2, 3], .init(ix: 0, iy: 0, iz: 0, r: 1)),
            smoothing: 0.0
        )
        XCTAssertEqual(result.position.x, 5, accuracy: 1e-5)
        XCTAssertEqual(result.position.y, 6, accuracy: 1e-5)
        XCTAssertEqual(result.position.z, 7, accuracy: 1e-5)
    }

    func testSmoothingHalfwayInterpolatesPosition() {
        let result = GrabMath.smoothedPose(
            current: ([0, 0, 0], .init(ix: 0, iy: 0, iz: 0, r: 1)),
            target: ([10, 0, 0], .init(ix: 0, iy: 0, iz: 0, r: 1)),
            smoothing: 0.5
        )
        XCTAssertEqual(result.position.x, 5, accuracy: 1e-5)
    }

    func testSmoothingClampsAboveOne() {
        // smoothing > 1 must clamp to 1 (snap), not overshoot
        let result = GrabMath.smoothedPose(
            current: ([0, 0, 0], .init(ix: 0, iy: 0, iz: 0, r: 1)),
            target: ([10, 0, 0], .init(ix: 0, iy: 0, iz: 0, r: 1)),
            smoothing: 5.0
        )
        XCTAssertEqual(result.position.x, 10, accuracy: 1e-5)
    }

    func testSmoothingProducesNormalizedRotation() {
        let result = GrabMath.smoothedPose(
            current: ([0, 0, 0], simd_quatf(angle: 0, axis: [0, 1, 0])),
            target: ([0, 0, 0], simd_quatf(angle: .pi, axis: [0, 1, 0])),
            smoothing: 0.5
        )
        XCTAssertEqual(simd_length(result.rotation.vector), 1.0, accuracy: 1e-4)
    }

    // MARK: - estimateVelocity

    func testVelocityZeroWithFewerThanTwoSamples() {
        let (lin, ang) = GrabMath.estimateVelocity([
            VelocitySample(position: [1, 1, 1], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 0)
        ])
        XCTAssertEqual(lin, .zero)
        XCTAssertEqual(ang, .zero)
    }

    func testVelocityZeroForEmptySamples() {
        let (lin, ang) = GrabMath.estimateVelocity([])
        XCTAssertEqual(lin, .zero)
        XCTAssertEqual(ang, .zero)
    }

    func testLinearVelocityFromLastTwoSamples() {
        // moved 0.2m in x over 0.1s -> 2 m/s
        let samples = [
            VelocitySample(position: [0, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 1.0),
            VelocitySample(position: [0.2, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 1.1)
        ]
        let (lin, _) = GrabMath.estimateVelocity(samples)
        XCTAssertEqual(lin.x, 2.0, accuracy: 1e-3)
        XCTAssertEqual(lin.y, 0.0, accuracy: 1e-3)
    }

    func testVelocityUsesOnlyTwoMostRecentSamples() {
        // Earlier samples must be ignored; only last two define velocity.
        let samples = [
            VelocitySample(position: [99, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 0.0),
            VelocitySample(position: [0, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 1.0),
            VelocitySample(position: [0.1, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 1.1)
        ]
        let (lin, _) = GrabMath.estimateVelocity(samples)
        XCTAssertEqual(lin.x, 1.0, accuracy: 1e-3)
    }

    func testVelocityGuardsAgainstZeroTimeDelta() {
        // Identical timestamps must not divide-by-zero / produce NaN.
        let samples = [
            VelocitySample(position: [0, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 2.0),
            VelocitySample(position: [0.5, 0, 0], rotation: .init(ix: 0, iy: 0, iz: 0, r: 1), time: 2.0)
        ]
        let (lin, _) = GrabMath.estimateVelocity(samples)
        XCTAssertFalse(lin.x.isNaN)
        XCTAssertTrue(lin.x.isFinite)
    }

    func testAngularVelocityFromRotationDelta() {
        // Rotate 90deg about Y over 0.5s -> ~ (pi/2)/0.5 rad/s about +Y.
        let q0 = simd_quatf(angle: 0, axis: [0, 1, 0])
        let q1 = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        let samples = [
            VelocitySample(position: .zero, rotation: q0, time: 0.0),
            VelocitySample(position: .zero, rotation: q1, time: 0.5)
        ]
        let (_, ang) = GrabMath.estimateVelocity(samples)
        XCTAssertEqual(ang.y, (.pi / 2) / 0.5, accuracy: 1e-2)
        XCTAssertEqual(ang.x, 0, accuracy: 1e-3)
        XCTAssertEqual(ang.z, 0, accuracy: 1e-3)
    }

    func testAngularVelocityZeroWhenNoRotation() {
        let q = simd_quatf(angle: 0.3, axis: simd_normalize(SIMD3<Float>(1, 1, 0)))
        let samples = [
            VelocitySample(position: .zero, rotation: q, time: 0.0),
            VelocitySample(position: [1, 0, 0], rotation: q, time: 0.1)
        ]
        let (_, ang) = GrabMath.estimateVelocity(samples)
        XCTAssertEqual(simd_length(ang), 0, accuracy: 1e-4)
    }
}
