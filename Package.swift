// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClippyTyperCore",
    platforms: [
        .macOS(.v13) // Primary target Sonoma, aim to run on Ventura+ for core logic
    ],
    products: [
        .library(name: "ClippyTyperCore", targets: ["ClippyTyperCore"]),
        .library(name: "ClippyTyperAppSupport", targets: ["ClippyTyperAppSupport"]),
        .library(name: "ClippyTyperPreferences", targets: ["ClippyTyperPreferences"]),
        .executable(name: "ClippyTyperApp", targets: ["ClippyTyperApp"]),
        .executable(name: "clippyctl", targets: ["clippyctl"])
    ],
    targets: [
        .target(name: "ClippyTyperCore"),
        .target(
            name: "ClippyTyperAppSupport",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon")
            ]
        ),
        .target(name: "ClippyTyperPreferences", path: "ClippyTyper/Preferences"),
        .executableTarget(
            name: "ClippyTyperApp",
            dependencies: [
                "ClippyTyperCore",
                "ClippyTyperPreferences",
                "ClippyTyperAppSupport"
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon")
            ]
        ),
        .executableTarget(name: "clippyctl"),
        .testTarget(name: "ClippyTyperCoreTests", dependencies: ["ClippyTyperCore"]),
        .testTarget(name: "ClippyTyperAppSupportTests", dependencies: ["ClippyTyperAppSupport"]) 
    ]
)
