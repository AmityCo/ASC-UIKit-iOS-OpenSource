// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedFrameworks",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SharedFrameworks",
            targets: ["SharedFrameworks", "AmitySDK", "AmityLiveVideoBroadcastKit", "AmityVideoPlayerKit", "MobileVLCKit", "AmityLiveKit", "LiveKitWebRTC"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SharedFrameworks",
            dependencies: []),
        .binaryTarget(
                    name: "AmitySDK",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.21.1/AmitySDK.xcframework.zip",
                    checksum: "2b7844d57248a83295fcb000cc91cdac5b551e085fa6fe1a6b95f84a9bcfaf35"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.21.1/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "f14a0b650153609e08704dbcae8d9ec8abd1fbd4f18dfef6454d2168d0ed0bea"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.21.1/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "2c917046c2a9f4a9d9ea69f0d1abf28c1d8442b2fd8bd61380f40b1cb417d307"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
        .binaryTarget(
                    name: "AmityLiveKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/d7485f57/AmityLiveKit.xcframework.zip",
                    checksum: "b5c6f8c569f434d8bbb966acdc62fdcf0bb456d84bf89f91995d95f5181c5b5e"
                ),
        .binaryTarget(
                    name: "LiveKitWebRTC",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/d7485f57/LiveKitWebRTC.xcframework.zip",
                    checksum: "b4787d18a681ef7a723aed3b0b246f54eba0f3b59d56a0a35b9905286af9e004"
                ),
    ]
)

