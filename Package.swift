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
        )
    ],
    targets: [
        .target(
            name: "CallToTheFaithful",
            path: "Sources/CallToTheFaithful"
        )
    ]
)
