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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.7/AmitySDK.xcframework.zip",
                    checksum: "64fa391f50185357e99f2a7808e293638a34f4d729defc7eba669b66c0da8fcd"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.7/Realm.xcframework.zip",
                    checksum: "576831b9099d51f3f1f74fb32846e98aebb56bdc473bee29a54feaf6a51ade9a"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.7/RealmSwift.xcframework.zip",
                    checksum: "0452dea625e0d6b3e674ae28cff5ab7fcf4442bfd5cb796190fd05b4f42ecb5e"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.7/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "19a06082e4b1818056a44ab2be5642198b4aa7dc0aecbe29391ae418a55a4bf1"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.7/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "2c383f29c4e1f78bc6442ee44165a3327024d91a8ad9a226c70224e70b45b84c"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

