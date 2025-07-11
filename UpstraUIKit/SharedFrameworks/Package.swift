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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.10.0/AmitySDK.xcframework.zip",
                    checksum: "f039c54113f64e0375e52a1075a3435e1fad90927b609fdb23dc5cf92567eba3"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.10.0/Realm.xcframework.zip",
                    checksum: "cb01a3e2e668fae48dcd10c93527707bc140e9d5661eb28725e8102ebab32f03"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.10.0/RealmSwift.xcframework.zip",
                    checksum: "478632f8d9b1c8e4476cb9455a061d3f4d7374f16d9c41d9f7708b704395bea7"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.10.0/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "9eb88c8519c7bacc6e23133e40c03b1fe158e6eb7e419efac01049157df6a3c9"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.10.0/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "b8d5a5d928a00ff2bef2b92d4b2383b60dbc890c9fa407d375c294ee12da4923"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

