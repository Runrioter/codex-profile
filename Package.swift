// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "codexp",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "codexp", targets: ["codexp"])],
    targets: [
        .executableTarget(
            name: "codexp",
            path: ".",
            exclude: ["AGENTS.md", "README.md", "Makefile", "tests"],
            sources: ["Sources/Codexp"],
            resources: [.copy("templates")]
        ),
        .testTarget(name: "CodexpTests", dependencies: ["codexp"], path: "tests/CodexpTests"),
    ]
)
