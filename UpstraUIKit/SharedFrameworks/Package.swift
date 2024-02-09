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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-3/AmitySDK.xcframework.zip",
                    checksum: "2e8698979508571dbb94a8787fd246ac4c1565294776e77f0371e19451fba44e"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-3/Realm.xcframework.zip",
                    checksum: "b73fed0bf99de0841f180c00bfb82dd30a061ab6e0827808878ab7539942964d"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-3/RealmSwift.xcframework.zip",
                    checksum: "1498fb5b7ad0579a7d1d40e734bc78440257c198cd4be26d425bd311db5a2932"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-3/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "35de20a59340e3389d304ea9dd7a2db5271c3ec98cbc9edfd606823af68d33ea"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.0.0-beta-3/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "b7a90fe1f4881a27ad923682958939df5cc3b4a63c46af90d6c3ae5599d21d1d"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

