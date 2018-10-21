// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "SPARQL",
    products: [
        .library(
            name: "SPARQL",
            targets: ["SPARQL"]),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "SPARQL",
            dependencies: []),
        .testTarget(
            name: "SPARQLTests",
            dependencies: ["SPARQL", "DiffedAssertEqual"]),
    ]
)
