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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.3.0/AmitySDK.xcframework.zip",
                    checksum: "6245e34b8d57a79994c45a7447739b053a12e8d3b58e04cdd46b3a6b3005cb5a"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.3.0/Realm.xcframework.zip",
                    checksum: "52f0aa04f2abf56183b0d9e11db0fab75c6a6af990e94dde9260d3ffe0ab0dbd"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.3.0/RealmSwift.xcframework.zip",
                    checksum: "c3f1d146142ad201a0ebfdb9abce6a0e9f4f6eee1a4a9abaced77e306ef2e293"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.3.0/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "27c8286c0ebcfc852c20c1f1654e854736820587202ea7fe1f14aa2dcc1eff25"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.3.0/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "fc442ed9898784589a2d07633a8442bb995c8c09bf4a3826546131d4ad4c0dd2"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

