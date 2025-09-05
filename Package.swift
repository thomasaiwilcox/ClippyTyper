// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClippyTyperCore",
    platforms: [
        .macOS(.v13) // Primary target Sonoma, aim to run on Ventura+ for core logic
    ],
    products: [
        .library(name: "ClippyTyperCore", targets: ["ClippyTyperCore"]),
        .library(name: "ClippyTyperPreferences", targets: ["ClippyTyperPreferences"]),
        .executable(name: "ClippyTyperApp", targets: ["ClippyTyperApp"])
    ],
    targets: [
        .target(name: "ClippyTyperCore"),
        .target(name: "ClippyTyperPreferences", path: "ClippyTyper/Preferences"),
        .executableTarget(
            name: "ClippyTyperApp",
            dependencies: [
                "ClippyTyperCore",
                "ClippyTyperPreferences"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon")
            ]
        ),
        .testTarget(name: "ClippyTyperCoreTests", dependencies: ["ClippyTyperCore"])
    ]
)
