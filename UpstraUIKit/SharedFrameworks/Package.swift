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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.1/AmitySDK.xcframework.zip",
                    checksum: "60d7de9431f649a2ecb572ec29e5c0070d576fcb6ca1ab02ece9f364e72b3682"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.1/Realm.xcframework.zip",
                    checksum: "c385b65974e803a74a021866becf061721458cb9b16ede0d2856eb4b90d8d7c4"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.1/RealmSwift.xcframework.zip",
                    checksum: "2636cfbb8f17954bc3784aa86a7f5aa9cb50c0fb6347549c1ccb57b0bcf7680e"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.1/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "e5582c92c2aa6702f33a1a7d190e450e794cef5bdeb88db60236d0ea586e6b43"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.1/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "a4de77159a105bf48c7886c9dd69001fafca9ce4c05c8750ae66f780da97891c"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

