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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4/AmitySDK.xcframework.zip",
                    checksum: "d1624c6808d76aa87a03ddac972962e59aa4d707f39efc5e6ccf73616dc47945"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4/Realm.xcframework.zip",
                    checksum: "0efee9680cc4c38380d2ebbe956539492a103e875379fc5d94c26bd6b6e0eae9"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4/RealmSwift.xcframework.zip",
                    checksum: "0ee4c34d71dc2bce0e06fdef237b597373fc4b3d53423a23fee4072ec9f75a27"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "25c3ae18105d9a60f6e2464cd95d637fcf1232b68152b3233b8a3f7156e052d5"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "5a2d7b41f6d60a1c33b50121f62cac39b8cf5d7598c7fff250509bd7caf57c37"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

