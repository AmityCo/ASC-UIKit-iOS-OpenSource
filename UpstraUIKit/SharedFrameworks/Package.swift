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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.5-xcode26.3/AmitySDK.xcframework.zip",
                    checksum: "ae3c934698378e44a21c9eeb0a86da0ecd648f3bce353c894221e0c6582a42b0"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.5-xcode26.3/Realm.xcframework.zip",
                    checksum: "36cb9604c1d9a9ba64d34e444e64fdb273a2d08b92383adc5c8b4fc26c4fe79f"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.5-xcode26.3/RealmSwift.xcframework.zip",
                    checksum: "2837a608abe7efe4656bd84e64b93ba7150b56b28a8584dcf5c0de2278cf0a60"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.5-xcode26.3/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "ce26cc63631169ec0267ef8625b2a173f36b1e597091a3ea9293e771e32c1206"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.5-xcode26.3/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "48bf450a2352a9597c43c1129adc677df7f9927d88168019518564902ad43ec5"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

