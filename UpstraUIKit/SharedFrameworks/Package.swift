// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedFrameworks",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SharedFrameworks",
            targets: ["SharedFrameworks", "AmitySDK", "Realm", "RealmSwift", "AmityLiveVideoBroadcastKit", "AmityVideoPlayerKit", "MobileVLCKit", "AmityLiveKit", "LiveKitWebRTC"]),
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
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta03-xcode26.3/AmitySDK.xcframework.zip",
                    checksum: "aab43b7c75dd4f8fc80d5c105977b2d5ed3be692892af839ff28d79174ceab8c"
                ),
        .binaryTarget(
                    name: "Realm",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta03-xcode26.3/Realm.xcframework.zip",
                    checksum: "1d80bc94da8b96325b0ec10cc7e2a34715e7cd4c100c8e6282722b1bc5d54623"
                ),
         .binaryTarget(
                    name: "RealmSwift",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta03-xcode26.3/RealmSwift.xcframework.zip",
                    checksum: "c16b2ad6b8a9cbd025f8ed9655971ace4147a8a987201b9af01cfdbfbad50716"
                ),
        .binaryTarget(
                    name: "AmityLiveVideoBroadcastKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta03-xcode26.3/AmityLiveVideoBroadcastKit.xcframework.zip",
                    checksum: "c8e81360154d14eb27bfbe47c1770f0f5b98db520f924be0012c032abc893700"
                ),
        .binaryTarget(
                    name: "AmityVideoPlayerKit",
                    url: "https://sdk.amity.co/sdk-release/ios-uikit-frameworks/4.17.0-beta03-xcode26.3/AmityVideoPlayerKit.xcframework.zip",
                    checksum: "f20e78f7d7f1813bda38a66206076132488c7389330ce40bf70f02378066bf92"
                ),
        .binaryTarget(
                    name: "MobileVLCKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/6.8.0/MobileVLCKit.xcframework.zip",
                    checksum: "23224e65575cdc18314937efb1af0ce8791f1ed567440e52fb0b6e37621bb9f3"
                ),
        .binaryTarget(
                    name: "AmityLiveKit",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/d7485f57/AmityLiveKit.xcframework.zip",
                    checksum: "b5c6f8c569f434d8bbb966acdc62fdcf0bb456d84bf89f91995d95f5181c5b5e"
                ),
        .binaryTarget(
                    name: "LiveKitWebRTC",
                    url: "https://sdk.amity.co/sdk-release/ios-frameworks/d7485f57/LiveKitWebRTC.xcframework.zip",
                    checksum: "b4787d18a681ef7a723aed3b0b246f54eba0f3b59d56a0a35b9905286af9e004"
                ),
    ]
)

