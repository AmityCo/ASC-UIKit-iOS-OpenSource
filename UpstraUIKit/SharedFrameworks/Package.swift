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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.3/AmitySDK.xcframework.zip",
                    checksum: "f2ad0cf406caade8d83d7e53e05c99a735cfa7d64a56540b1115aeeb1f6f7132"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.3/Realm.xcframework.zip",
                    checksum: "c098607fe2ed12b7b6d9b9115ca6a937fd1b4364925f244c8e4fde57e75ffc05"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.3/RealmSwift.xcframework.zip",
                    checksum: "dd8a29b31847c1a695163519f83e675c2bc1383602fbcc249bde981e2d4f8c83"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.3/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "15ae44b408478ed2cd922e9b5d66a8e8df1ed7b051cdeca6e39b9e92b953b467"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.16.3/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "cef25f9246a75dba0c21182b4c7b2a46a58e73f77bac7b4311ae349a2628e5ae"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
    ]
)

