// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NativeWebview",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NativeWebview",
            targets: ["NativeWebviewPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "NativeWebviewPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/NativeWebviewPlugin"),
        .testTarget(
            name: "NativeWebviewPluginTests",
            dependencies: ["NativeWebviewPlugin"],
            path: "ios/Tests/NativeWebviewPluginTests")
    ]
)