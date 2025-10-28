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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.15.0/AmitySDK.xcframework.zip",
                    checksum: "4e69d56b0fee821deaa818b7d62157fd71596fcf527ce3e8da57b209345527e8"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.15.0/Realm.xcframework.zip",
                    checksum: "3a173272f2d1e71fbb115e0dc7fee16c97e10f9fd79f5005cefebabcfb76a277"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.15.0/RealmSwift.xcframework.zip",
                    checksum: "ededc7d1df23a8ac866a531fede8b93fe80d6eedf1b89d4b39d82affb9d5b7b1"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.15.0/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "b9a6baf6ed48d1577fde063d082304d85c930ca0b93676355be616a997ad7eb1"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.15.0/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "2bffab6e110d5a03195f439f12f3958b23dc0f7750d5b2c73cc00a8a952a748b"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

