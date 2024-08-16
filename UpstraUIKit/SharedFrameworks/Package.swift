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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.10/AmitySDK.xcframework.zip",
                    checksum: "392479f21a7a845fcfa3c12c23faff08d6e41f903c5916de9c9ed35d9e33e233"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.10/Realm.xcframework.zip",
                    checksum: "b0a2c25ce8678279c1452741b3a310bea9e3869df7bbda85e73395f2b641b10d"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.10/RealmSwift.xcframework.zip",
                    checksum: "a3164683df233bc79aefdbd7c92158a1c3025ccfc596f1d8022e9dfc2c0bd382"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.10/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "aead7e72dbe90f2213e9a135e2003131743b30fc04042b37bf7b81ebd7f98e55"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.10/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "749708fe4ac83bd4db403e707b88fe1cd1a4f431abd9eb71bcbcff5506e9ddd3"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

