// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "FRConjugation",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "FRConjugation",
            targets: ["FRConjugation"]
        )
    ],
    targets: [
        .target(
            name: "FRConjugation",
            path: "swift/Sources/FRConjugation",
            resources: [
                .copy("Resources/catalogue.fcr")
            ]
        ),
        .testTarget(
            name: "FRConjugationTests",
            dependencies: ["FRConjugation"],
            path: "swift/Tests/FRConjugationTests",
            resources: [.copy("Fixtures/conformance.tsv"), .copy("Fixtures/typed-api.tsv")]
        ),
    ]
)
