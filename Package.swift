// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FuturaNetwork",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "FuturaNetwork",
            targets: ["FuturaNetwork"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/kaqu/FuturaAsync.git", from: "0.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "FuturaNetwork",
            dependencies: ["FuturaAsync"]),
        .testTarget(
            name: "FuturaNetworkTests",
            dependencies: ["FuturaNetwork"]),
    ]
)
