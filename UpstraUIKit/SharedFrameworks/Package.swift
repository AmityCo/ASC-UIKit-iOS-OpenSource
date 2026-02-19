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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode26.1/AmitySDK.xcframework.zip",
                    checksum: "71f079a8989eb95c7e240fe836dd136e301fe76e05a962b9beb869954794f379"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode26.1/Realm.xcframework.zip",
                    checksum: "e7cbc5c737cd4116542bbc8d8fb647f86ad787a3377f4a7d8eeb121990919b66"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode26.1/RealmSwift.xcframework.zip",
                    checksum: "63a9f5a8a167513659af79687128cc6c730b359cd6ca60018479d476be6604fe"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode26.1/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "4f628c51db7a125240bfd4f041a1879a753f10490b74492c4822dc49d49677f9"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode26.1/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "0656e98a7dfa4dcdb1952d24514e459dbedeb2752bc20d83d797c0bc6913ec48"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

