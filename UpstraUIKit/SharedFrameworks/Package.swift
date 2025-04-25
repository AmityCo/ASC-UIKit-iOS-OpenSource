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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.6.0/AmitySDK.xcframework.zip",
                    checksum: "00bbc7b853264dfcb79ea18b50807f84fe00f3ec74bf5659291a89efcb8317f5"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.6.0/Realm.xcframework.zip",
                    checksum: "e22c477af21f25546db26d1235d687f049ded1ba0aa62fb976ccb892b1aa96e8"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.6.0/RealmSwift.xcframework.zip",
                    checksum: "ee2eab6e2698284f671b2e96b6c33bc5ce2da001cb0a92af671744ca32ef4dd6"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.6.0/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "b2f12423f593cd38acdba9d965137a8b03e6b2f06339fc884a853b99203efe9f"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.6.0/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "efd003f02e2f02ff8427a4a5e8c6eb778d843ef852048787c43b097d23f95b50"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

