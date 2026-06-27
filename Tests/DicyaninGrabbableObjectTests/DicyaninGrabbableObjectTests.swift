import XCTest
import simd
@testable import DicyaninGrabbableObject

final class DicyaninGrabbableObjectTests: XCTestCase {

    func testHoldAngleProducesNormalizedQuaternion() {
        let q = DicyaninGrabbableComponent.holdAngle(pitch: 90, yaw: 0, roll: 0)
        XCTAssertEqual(simd_length(q.vector), 1.0, accuracy: 1e-4)
    }

    func testDefaultGrabbableConfig() {
        let c = DicyaninGrabbableComponent()
        XCTAssertFalse(c.isGrabbed)
        XCTAssertNil(c.grabbingHandID)
        XCTAssertEqual(c.grabRadius, 0.12, accuracy: 1e-6)
    }

    func testRealisticDropDefaults() {
        let d = DropBehavior.realisticDrop
        XCTAssertTrue(d.inheritVelocity)
        if case .physics = d.mode {} else { XCTFail("expected .physics") }
    }

    func testDropPathOrdering() {
        let path = DropPath(waypoints: [
            .init(position: [0, -0.1, 0], time: 0.2),
            .init(position: [0, 0, 0], time: 0.0)
        ])
        XCTAssertEqual(path.waypoints.count, 2)
    }
}
