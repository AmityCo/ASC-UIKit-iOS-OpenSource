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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta02-xcode26.1/AmitySDK.xcframework.zip",
                    checksum: "7549a0e6c455c67277abb395c28b053fb3bea3211ccf7b1b9a5b276ff52bde10"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta02-xcode26.1/Realm.xcframework.zip",
                    checksum: "d52f2cd6d2d6440787165fb70c767cead08d639701d87238d6d5a193c1e5fc95"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta02-xcode26.1/RealmSwift.xcframework.zip",
                    checksum: "03abb45972419ba714a36f1baa494d4f0091f840cd52e444483919ea9de1199e"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta02-xcode26.1/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "446cf4153010aeb57882b2eeb3218012d0b3d79d8de28507d65f0933739d7d68"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta02-xcode26.1/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "eb9fb992573eef89c13ac86599cc260b8786e4ba8be378b5b7fc241fa037991f"
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

