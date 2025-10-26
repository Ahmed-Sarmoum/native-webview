// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NativeWebview",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NativeWebview",
            targets: ["NativeWebiewPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "NativeWebiewPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/NativeWebiewPlugin"),
        .testTarget(
            name: "NativeWebiewPluginTests",
            dependencies: ["NativeWebiewPlugin"],
            path: "ios/Tests/NativeWebiewPluginTests")
    ]
)