// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedFrameworks",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SharedFrameworks",
            targets: ["SharedFrameworks", "AmitySDK", "Realm", "RealmSwift", "AmityLiveVideoBroadcastKit", "AmityVideoPlayerKit", "MobileVLCKit"]),
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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.19.2-xcode26.5/AmitySDK.xcframework.zip",
                    checksum: "c3c0746449139f8738dfeb7edc80f417f2ad25d12ad51a70736371f50f34b515"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.19.2-xcode26.5/Realm.xcframework.zip",
                    checksum: "000b07e2e11993dfe2e584c0c254386af33d81da5302a01f2f21368ffa3cba31"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.19.2-xcode26.5/RealmSwift.xcframework.zip",
                    checksum: "9657f045355084c96288c755a5cf67c39fba0541c4a22e6b0f0fa8839f139358"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.19.2-xcode26.5/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "9975ad8dc9f4fb43fa184325c87f2ab320637c5f09e9ab01302ecf35af308aa1"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.19.2-xcode26.5/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "dce6015aba796c3f390b2636aee02752b6bb81f866f13eb7f8cd0b0d405599a2"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

