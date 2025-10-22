// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CallToTheFaithful",
    platforms: [
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "CallToTheFaithful",
            targets: ["CallToTheFaithful"]
        ),
        .library(
            name: "CallToTheFaithfulWidget",
            targets: ["CallToTheFaithfulWidget"]
        )
    ],
    targets: [
        .target(
            name: "CallToTheFaithful",
            path: "Sources",
            sources: [
                "CallToTheFaithful",
                "Models",
                "Storage"
            ]
        ),
        .target(
            name: "CallToTheFaithfulWidget",
            dependencies: ["CallToTheFaithful"],
            path: "Sources/CallToTheFaithfulWidget"
        )
    ]
)
