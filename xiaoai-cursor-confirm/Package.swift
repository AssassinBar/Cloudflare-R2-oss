// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XiaoAiCursorConfirm",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "XiaoAiCursorConfirm", targets: ["XiaoAiCursorConfirm"])
    ],
    targets: [
        .executableTarget(
            name: "XiaoAiCursorConfirm",
            path: "Sources/XiaoAiCursorConfirm",
            exclude: [
                "Resources/Info.plist",
                "Resources/XiaoAiCursorConfirm.entitlements"
            ],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Network"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
