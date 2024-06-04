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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.6/AmitySDK.xcframework.zip",
                    checksum: "21c6c9f78cc63d1923914d3bf7ef3bc1d9047e2f100ecd016e9f1e3df6e5c3d2"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.6/Realm.xcframework.zip",
                    checksum: "58d7a17b793a4248b4320d73bb8dd6b8a189f258c079de966178f5de1076b371"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.6/RealmSwift.xcframework.zip",
                    checksum: "5455713438ed64afcd3a531775e0289ec8211d17ea3c1f574bce243a9a5472aa"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.6/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "a1ece835f7190e4c90b8022edea8a58f2412003d5a8f3b64561f221b9930fa92"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.6/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "5662fcbfbd03aa6350631355a3578e4a90bc8082173ce4fe42c8eecf9c91b3e2"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

