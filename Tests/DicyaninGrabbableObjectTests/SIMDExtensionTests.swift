//
//  SIMDExtensionTests.swift
//  Covers the small SIMD helpers the System relies on for world-space math:
//  SIMD4.xyz and simd_float4x4.xyz (translation column).
//

import XCTest
import simd
@testable import DicyaninGrabbableObject

final class SIMDExtensionTests: XCTestCase {

    func testSIMD4DropsWComponent() {
        let v = SIMD4<Float>(1, 2, 3, 1)
        XCTAssertEqual(v.xyz, SIMD3<Float>(1, 2, 3))
    }

    func testMatrixXYZReturnsTranslationColumn() {
        var t = matrix_identity_float4x4
        t.columns.3 = SIMD4<Float>(0.5, -0.25, 4, 1)
        XCTAssertEqual(t.xyz, SIMD3<Float>(0.5, -0.25, 4))
    }

    func testHomogeneousPointTransformExtractsPosition() {
        // Mirrors how the System computes a grab point: (matrix * point).xyz
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(1, 1, 1, 1) // pure translation
        let localOffset = SIMD3<Float>(0.1, 0.2, 0.3)
        let world = (m * SIMD4<Float>(localOffset, 1)).xyz
        XCTAssertEqual(world.x, 1.1, accuracy: 1e-5)
        XCTAssertEqual(world.y, 1.2, accuracy: 1e-5)
        XCTAssertEqual(world.z, 1.3, accuracy: 1e-5)
    }
}
