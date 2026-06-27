//
//  SpatialGrabGesture.swift
//  DicyaninGrabbableObject
//
//  Optional SwiftUI helper. On visionOS, a SpatialEventGesture gives you
//  pinch begin/end which is the simplest way to drive a grabber's isGrabbing
//  state without writing raw ARKit hand-tracking. For full fist-grab realism,
//  drive setGrabbing(_:) yourself from ARKit HandTrackingProvider instead.
//

#if os(visionOS)
import SwiftUI
import RealityKit

public extension View {

    /// Drives a grabber entity's grab state from pinch events.
    /// - Parameters:
    ///   - grabber: the hand/grabber entity to toggle.
    ///   - onChange: optional callback (true = grabbing started).
    func dicyaninPinchGrab(_ grabber: Entity, onChange: ((Bool) -> Void)? = nil) -> some View {
        self.gesture(
            SpatialEventGesture()
                .onChanged { events in
                    let active = events.contains { $0.phase == .active }
                    grabber.setGrabbing(active)
                    onChange?(active)
                }
                .onEnded { _ in
                    grabber.setGrabbing(false)
                    onChange?(false)
                }
        )
    }
}
#endif
