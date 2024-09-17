    // swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CodableCSV",
    platforms: [
        .macOS(.v12),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "CodableCSV",
            targets: ["CodableCSV"]
        )
    ],
    dependencies: [
        // Add any external package dependencies here, if needed.
    ],
    targets: [
        .target(
            name: "CodableCSV",
            path: "sources"
        ),
        .testTarget(
            name: "CodableCSVTests",
            dependencies: ["CodableCSV"],
            path: "tests"
        ),
        .testTarget(
            name: "CodableCSVBenchmarks",
            dependencies: ["CodableCSV"],
            path: "benchmarks"
        )
    ]
)
