//
//  GrabberComponentTests.swift
//  Covers DicyaninGrabberComponent (the hand side): defaults, chirality,
//  custom config, and initial held state.
//

import XCTest
import simd
@testable import DicyaninGrabbableObject

final class GrabberComponentTests: XCTestCase {

    func testDefaults() {
        let g = DicyaninGrabberComponent()
        XCTAssertEqual(g.grabRadius, 0.04, accuracy: 1e-6)
        XCTAssertEqual(g.anchorOffset, .zero)
        XCTAssertFalse(g.isGrabbing)
        XCTAssertNil(g.heldEntityID)
        if case .either = g.chirality {} else { XCTFail("expected default .either") }
    }

    func testCustomConfiguration() {
        let g = DicyaninGrabberComponent(
            chirality: .left,
            anchorOffset: [0, -0.02, 0.03],
            grabRadius: 0.06,
            isGrabbing: true
        )
        if case .left = g.chirality {} else { XCTFail("expected .left") }
        XCTAssertEqual(g.anchorOffset, [0, -0.02, 0.03])
        XCTAssertEqual(g.grabRadius, 0.06, accuracy: 1e-6)
        XCTAssertTrue(g.isGrabbing)
    }

    func testRightChirality() {
        let g = DicyaninGrabberComponent(chirality: .right)
        if case .right = g.chirality {} else { XCTFail("expected .right") }
    }
}
