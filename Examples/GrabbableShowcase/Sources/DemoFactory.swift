//
//  DemoFactory.swift
//  GrabbableShowcase
//
//  Shared builders so the immersive showcase and the SpatulaPreviewView use
//  the exact same object configuration.
//

import UIKit
import RealityKit
import simd
import DicyaninGrabbableObject

enum DemoFactory {

    static func colorMat(_ c: UIColor) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: c)
        mat.roughness = 0.4
        mat.metallic = 0.1
        return mat
    }

    /// An orange spatula (brown handle + flat blade) configured to be grabbed by
    /// its handle and held at an angle. Pass `debug: true` to show the grab area.
    static func spatula(debug: Bool = false) -> Entity {
        let spatula = Entity()

        let handle = ModelEntity(
            mesh: .generateBox(size: [0.02, 0.16, 0.02], cornerRadius: 0.01),
            materials: [colorMat(.brown)]
        )
        handle.position = [0, -0.06, 0]

        let blade = ModelEntity(
            mesh: .generateBox(size: [0.06, 0.08, 0.006], cornerRadius: 0.005),
            materials: [colorMat(.orange)]
        )
        blade.position = [0, 0.06, 0]

        spatula.addChild(handle)
        spatula.addChild(blade)

        spatula.makeGrabbable(DicyaninGrabbableComponent(
            holdRotation: DicyaninGrabbableComponent.holdAngle(pitch: -70, yaw: 0, roll: 0),
            grabOffset: [0, 0, 0.015],
            collisionShapeOffset: [0, -0.06, 0],          // the handle
            collisionShapeExtents: [0.025, 0.07, 0.025],
            grabRadius: 0.06,
            followSmoothing: 0.4,
            dropBehavior: .realisticDrop,
            showDebugVisualization: debug
        ))
        return spatula
    }
}
