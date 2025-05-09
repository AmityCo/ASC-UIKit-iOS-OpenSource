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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.7.0/AmitySDK.xcframework.zip",
                    checksum: "ca4e0f014484a4b1fd274196f61ba5d3c0c70dfeaec460b24b6c926bac54271b"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.7.0/Realm.xcframework.zip",
                    checksum: "c62343fbeb1bc8544d3e685f02b5045e6d68a31c5dbbab31658907a60c2e903d"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.7.0/RealmSwift.xcframework.zip",
                    checksum: "8a5d12f89cc4a4d93d4389d545650ef59320b608ce63af5dbc367b40adb4b0bf"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.7.0/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "a1e78610eef64cb7b66d08a61453d25dca27900f823cff992b0746fa2fdbfa11"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.7.0/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "37e07fcc7a6432616926f91ba2431beb058357a9283ad6da86ebe45e312fd46f"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

