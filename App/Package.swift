// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "App",
    platforms: [.macOS(.v12)],
    products: [
        .library(
            name: "App",
            targets: ["App"]),
    ],
    dependencies: [
        .package(
            name: "LaunchAtLogin",
            url: "https://github.com/sindresorhus/LaunchAtLogin",
            .upToNextMajor(from: "4.2.0")
        ),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: ["LaunchAtLogin"]),
    ]
)
