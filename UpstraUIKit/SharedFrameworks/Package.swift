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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta19/AmitySDK.xcframework.zip",
                    checksum: "c1d56b5c7328cfb6c64a7e3893a2f57a22ce54909a60d0963111e28f1c10b8d3"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta19/Realm.xcframework.zip",
                    checksum: "6a5572a8798c32cc8f14918703b4e19bcd32351bfeac6d3b43191739726eaa7b"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta19/RealmSwift.xcframework.zip",
                    checksum: "8fb529cf5322f15015d581f149bf4c926808bc7739173c2a6f7fd84dd33a9ec6"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta19/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "85e16bcf835d4af2462552d2b51688b8b95e187451e86309f35ec054326c3d5a"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta19/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "63ab95cba71e2be0b9e2d37c34d70247372e13a246f900e469ed5bd2e140f821"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

