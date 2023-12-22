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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta01/AmitySDK.xcframework.zip",
                    checksum: "b623f3a3c51a0d06551addb6bc2a6569ce32a0d9ccddae8740b94b6eef41f125"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta01/Realm.xcframework.zip",
                    checksum: "57e27aceb021c8f79d96901c76938529b43ee5046cde90271d47994e2c1f67ef"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta01/RealmSwift.xcframework.zip",
                    checksum: "0eae1ccd6c85b6c5f2e54a0c43f01499c18c11065c59e105533ba9c9a336f663"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta01/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "405a5f4dd581fd2f6a2a6b5c755af57c967a6dcaae90ba6642f1f52ca99d5bec"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta01/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "adc1b45d7ff851bb77adff11116944aa8f5390cd300e7fa527ef99a8d61f1bcf"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

