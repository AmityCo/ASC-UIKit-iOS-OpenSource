// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedFrameworks",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SharedFrameworks",
            targets: ["SharedFrameworks", "AmitySDK", "Realm", "RealmSwift", "AmityLiveVideoBroadcastKit", "AmityVideoPlayerKit", "MobileVLCKit", "AmityLiveKit", "LiveKitWebRTC"]),
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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.18.1-xcode26.3/AmitySDK.xcframework.zip",
                    checksum: "345228b6dd98a48642ee2e74cf5dc25d0ae752c1cb70d1a7d89ec1d4900c19c1"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.18.1-xcode26.3/Realm.xcframework.zip",
                    checksum: "86a6cebfe151af00912b3f82780bfd53c52fce13cc1a0854fabbc4a77992f7dd"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.18.1-xcode26.3/RealmSwift.xcframework.zip",
                    checksum: "c52d40b9c6fa99e408e5ef9ba2a05b77b811aea27eb58478b7c19907a58c7950"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.18.1-xcode26.3/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "0e934deea79f656968915998c4c73020727e6093d708d0688066d03823130011"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.18.1-xcode26.3/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "508d257c1f7394e28b717879016472b0bd6f2e13e0cbe984ab39814f435de2b9"
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

