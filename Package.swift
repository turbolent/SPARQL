// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SPARQL",
    products: [
        .library(
            name: "SPARQL",
            targets: ["SPARQL"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/turbolent/DiffedAssertEqual.git", from: "0.2.0"),
    ],
    targets: [
        .target(
            name: "SPARQL",
            dependencies: []
        ),
        .testTarget(
            name: "SPARQLTests",
            dependencies: ["SPARQL", "DiffedAssertEqual"]
        ),
    ]
)
