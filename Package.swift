// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AVOpusAsset",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "AVOpusAsset",
            targets: ["AVOpusAsset"]
        ),
    ],
    targets: [
        .target(
            name: "Opus",
            cSettings: [
                .headerSearchPath("celt"),
                .headerSearchPath("silk"),
                .headerSearchPath("silk/float"),

                .define("OPUS_BUILD"),
                .define("VAR_ARRAYS", to: "1"),
                
                .define("FLOATING_POINT"),
                .define("HAVE_DLFCN_H", to: "1"),
                .define("HAVE_INTTYPES_H", to: "1"),
                .define("HAVE_LRINT", to: "1"),
                .define("HAVE_LRINTF", to: "1"),
                .define("HAVE_MEMORY_H", to: "1"),
                .define("HAVE_STDINT_H", to: "1"),
                .define("HAVE_STDLIB_H", to: "1"),
                .define("HAVE_STRING_H", to: "1"),
                .define("HAVE_STRINGS_H", to: "1"),
                .define("HAVE_SYS_STAT_H", to: "1"),
                .define("HAVE_SYS_TYPES_H", to: "1"),
                .define("HAVE_UNISTD_H", to: "1"),
            ]
        ),
        .target(
            name: "AVOpusAsset",
            dependencies: [ "Opus" ]
        )
    ]
)
