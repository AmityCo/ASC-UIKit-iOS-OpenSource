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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.3/AmitySDK.xcframework.zip",
                    checksum: "1ce47358c22e89d3b3cc20e0e130dfb7f27d2b80381d40199a26765f218ebca5"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.3/Realm.xcframework.zip",
                    checksum: "a21f089b3962c74abbc6234c94d3954598b7c079d532284f1d1aeaf372b1c2e3"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.3/RealmSwift.xcframework.zip",
                    checksum: "05fdcb643f06ab9b80b92ac591092d3ef45b7c4b348d04aa2e8cadcff0244311"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.3/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "c9fbd22640bbbe6b03ddae19ccaccb3f476f0cd6dbd1108ccbb250385adf9e39"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.3/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "ee4c5e5c233b58a226c8c0f9e96208038e74915a6de6a577c38779c1a2ebff0b"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

