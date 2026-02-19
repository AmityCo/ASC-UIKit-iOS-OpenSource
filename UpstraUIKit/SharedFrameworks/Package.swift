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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode16.4/AmitySDK.xcframework.zip",
                    checksum: "83ee215acf427ba8d74976c8d5f79796c9a88bc0643f335c04d450b785b761e2"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode16.4/Realm.xcframework.zip",
                    checksum: "a27cc504eb98b756da214aecdba32a181c3f1f5e01fa35e0a26a884eb9f05c1d"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode16.4/RealmSwift.xcframework.zip",
                    checksum: "069752d89f9fd3d8afcc3b75b5dc7951024feec7ac25812317ae44cb642fe143"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode16.4/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "05ed06d282de3dc13dec30df2d07eff967ec77b69936443f544980c8a59f3460"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.4-xcode16.4/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "d1e513071f8417b2307da45f5a8d75307da0e008b526832c5464f5cd30bcaa61"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

