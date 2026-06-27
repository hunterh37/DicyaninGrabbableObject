# DicyaninGrabbableObject

A RealityKit / visionOS Swift package for **realistic, physically-grounded object grabbing**. Add one component to an object, one to a hand, and the user can reach out, grab it (held at a configurable angle and grip point), and release it — at which point your customizable drop behavior takes over (gravity, throw-velocity inheritance, freeze, or a hand-authored drop path).

> Example: reach out and grab a spatula. It locks to your hand at its hold angle, the handle aligned to your fingers. Release the grab gesture and it falls — inheriting your hand's motion so a flick throws it.

## Install

Swift Package Manager:

```swift
.package(url: "https://github.com/dicyanin/DicyaninGrabbableObject.git", from: "1.0.0")
```

Platforms: visionOS 2+, iOS 18+ (RealityKit).

## Quick start

```swift
import DicyaninGrabbableObject

// 1. Register once at launch.
DicyaninGrabbable.registerComponents()

// 2. Make an object grabbable (e.g. a spatula).
spatula.makeGrabbable(
    DicyaninGrabbableComponent(
        holdRotation: DicyaninGrabbableComponent.holdAngle(pitch: -75, yaw: 0, roll: 0),
        grabOffset: [0, 0, 0.02],            // sit the handle in the palm
        collisionShapeOffset: [0, -0.12, 0], // grab the handle, not the blade
        collisionShapeExtents: [0.02, 0.06, 0.02],
        grabRadius: 0.10,
        followSmoothing: 0.4,                 // weighty but responsive
        dropBehavior: .realisticDrop          // gravity + throw inheritance
    )
)

// 3. Mark your hand anchors as grabbers.
leftHandAnchor.makeGrabber(DicyaninGrabberComponent(chirality: .left, anchorOffset: [0, 0, 0]))
rightHandAnchor.makeGrabber(DicyaninGrabberComponent(chirality: .right))
```

## Driving the grab gesture

The system reacts to each grabber's `isGrabbing` flag. Drive it however you like:

**Simplest (pinch, SwiftUI):**
```swift
RealityView { ... }
    .dicyaninPinchGrab(rightHandAnchor)
```

**Most realistic (ARKit fist detection):** in your `HandTrackingProvider` loop, compute whether the fingers are curled and call:
```swift
rightHandAnchor.setGrabbing(isFistClosed)
```

## Key concepts

| Piece | Where it goes | What it controls |
|---|---|---|
| `DicyaninGrabbableComponent` | the object | hold angle, grip offset, grab collision shape/offset, follow weight, drop behavior |
| `DicyaninGrabberComponent` | the hand anchor | palm anchor offset, chirality, live `isGrabbing` state |
| `DicyaninGrabSystem` | registered globally | latches, holds (kinematic follow + velocity sampling), and releases |
| `DropBehavior` | inside the grabbable | `.realisticDrop` · `.freezeInPlace` · `.customPath(...)` · `.custom { }` |

## Drop behaviors

```swift
// Gravity + throw inheritance (default)
.dropBehavior = .realisticDrop

// Hang in place where released
.dropBehavior = .freezeInPlace

// Hand-authored arc, then gravity
.dropBehavior = DropBehavior(mode: .customPath(
    DropPath(waypoints: [
        .init(position: [0, 0.05, 0], time: 0.15),   // little hop up
        .init(position: [0, -0.20, 0.10], time: 0.6)  // then arc forward
    ], handOffToPhysics: true)
))

// Fully custom
.dropBehavior = DropBehavior(mode: .custom { entity, ctx in
    // ctx.linearVelocity, ctx.worldPosition, etc.
})
```

## How "realism" is achieved

- **Kinematic hold:** while grabbed, physics is suspended and the object is driven to `handAnchor * grabOffset` with `holdRotation`, using per-frame slerp/lerp (`followSmoothing`) so it feels weighty rather than glued.
- **Velocity sampling:** the last several frames of motion are recorded so releasing transfers real linear + angular velocity (throwing works).
- **Grab sweet spot:** `collisionShapeOffset` + `collisionShapeExtents` define exactly where on the object a hand must reach to latch — so a spatula is grabbed by its handle.

## Refinements baked into the design

Your original idea, sharpened:
1. **Separated the grab point from the hold pose.** Where you *touch* it (`collisionShapeOffset`) is independent of how it *sits in your hand* (`grabOffset` + `holdRotation`). Real tools need both.
2. **Velocity inheritance** so release isn't just "drop" — flicks become throws.
3. **Pluggable `DropBehavior`** with four modes instead of only gravity, covering placing, throwing, and scripted arcs.
4. **Follow smoothing** for weight, instead of rigid locking that breaks immersion.
5. **Two-line setup** via `Entity.makeGrabbable` / `makeGrabber` extensions.
