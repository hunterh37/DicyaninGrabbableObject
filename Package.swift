// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DicyaninGrabbableObject",
    platforms: [
        .visionOS(.v2),
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "DicyaninGrabbableObject",
            targets: ["DicyaninGrabbableObject"]
        )
    ],
    targets: [
        .target(
            name: "DicyaninGrabbableObject"
        ),
        .testTarget(
            name: "DicyaninGrabbableObjectTests",
            dependencies: ["DicyaninGrabbableObject"]
        )
    ]
)
