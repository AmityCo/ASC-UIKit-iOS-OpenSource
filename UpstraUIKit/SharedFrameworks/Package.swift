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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-9/AmitySDK.xcframework.zip",
                    checksum: "8c6a53d402c102c1e6ec6e2a3aec2962a617d478a1e2353ae2ba70e0107c9600"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-9/Realm.xcframework.zip",
                    checksum: "78ab6f17f1de546139eca80103a6f732fcba308c0be30ef01da4f692a1d7aed7"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-9/RealmSwift.xcframework.zip",
                    checksum: "f64a3f356cfc2ed29ba1dcc9439368954891f7d51576cc06c2111b60737a3ca6"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-9/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "d1aa6c584b80142e01c3e435e4dda794f16ccc56ca7d083f34dd8d029b396908"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-9/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "8c82c0401f3db9f1f11ae30663cade1aaf2d55a4502a95e1b07debca7012a285"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

