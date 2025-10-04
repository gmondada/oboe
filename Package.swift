// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "oboe",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "oboe",
            targets: ["oboe"]),
        .executable(
            name: "dev",
            targets: ["dev"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "oboe",
            dependencies: [],
            path: "spm",
            sources: ["src"],
            publicHeadersPath: "public",
            cSettings: [
                .headerSearchPath("src"),
                .headerSearchPath("inc"),
                .headerSearchPath("public")
            ],
            cxxSettings: [
                .headerSearchPath("src"),
                .headerSearchPath("inc"),
                .headerSearchPath("public"),
                .define("ANDROID"),
                .define("_FORTIFY_SOURCE", to: "2"),
                .define("NDEBUG", .when(configuration: .release))
            ],
            linkerSettings: [
                .linkedLibrary("log"),
                .linkedLibrary("OpenSLES"),
                .linkedLibrary("atomic"),
                .linkedLibrary("m")
            ]
        ),
        .executableTarget(
            name: "dev",
            path: "spm/dev",
        ),
    ],
    cxxLanguageStandard: .cxx17
)