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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta27/AmitySDK.xcframework.zip",
                    checksum: "f926caa2b3305e96ce9928471026618a7788d230d6b5f59b6280baa5e4d2241d"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta27/Realm.xcframework.zip",
                    checksum: "465f5a2a03933b80091a0503e054e3b5c4a60d93d7f9970d7fd209a9cb3c354b"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta27/RealmSwift.xcframework.zip",
                    checksum: "3bd79319006e5fc9bd3950f7be7f7f38016f60f3e2e0a8825f6327ca87e29150"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta27/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "e1db89c8c979d972f3b89aeb47acf6505a95e6155d7416082247264eacb2b084"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta27/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "7f22cc7aceba386cadc42457468f12f86c827cbbc9237a07aa800ca978a3b8cd"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

