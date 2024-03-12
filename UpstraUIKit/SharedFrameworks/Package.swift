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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.1/AmitySDK.xcframework.zip",
                    checksum: "8c45106cad0573321e47e3b950b606da04a7d6fc8bfc38d087a8660a95b9e8f5"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.1/Realm.xcframework.zip",
                    checksum: "0ff659849ad0e029babab31127d9073a0b8634ae8f68672e9495b7fe0b22fd20"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.1/RealmSwift.xcframework.zip",
                    checksum: "51903bee43723661279eb4db06dd490386354080bf342d784244408ff50e5663"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.1/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "01f67a2d7f0a769360247df7ee286eb9d946cf9c1acb3b594fdd41efd0cd080a"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/3.20.1/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "de87774d22cb0e2ab35b8f8a4cdc5ae22b641f7210fb3f0e0c6553c0adafa2d6"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

