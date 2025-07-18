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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.0/AmitySDK.xcframework.zip",
                    checksum: "54492b646c1c61ac84a3973fd0e752ce5704ff8cf7e1716186ade9c4e1f6d2ed"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.0/Realm.xcframework.zip",
                    checksum: "8d6ddbd1721b7ae3c3f64c2628c3e24ff6fb24fc03620c26cc3cd59583894f33"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.0/RealmSwift.xcframework.zip",
                    checksum: "e1a0c87333212aa38b497180010a6df4c0c91012925d61e716a83726b9d00c6a"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.0/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "53ff83a59c95e7a34e58543b71a65bce2b01ae04c0bfcab768bb13c1b4e5e940"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.11.0/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "6345d3c2957d37df24726b2b29d9a28b696e21ebad182dcf61f893c9a36083fe"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

