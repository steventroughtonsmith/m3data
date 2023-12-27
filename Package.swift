// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "M3Data",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "M3Data", targets: ["M3Data"]),
		.executable(name: "M3DataClient", targets: ["M3DataClient"]),
    ],
    dependencies: [
        // Depend on the Swift 5.9 release of SwiftSyntax
		.package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Macro implementation that performs the source transformation of a macro.
		.macro(name: "M3DataMacros", dependencies: [
			.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
			.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
		]),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(name: "M3Data", dependencies: ["M3DataMacros"]),

        // A client of the library, which is able to use the macro in its own code.
         .executableTarget(name: "M3DataClient", dependencies: ["M3Data"]),

        // Test target for the framework
        .testTarget(name: "M3DataTests", dependencies: ["M3Data"]),

        // A test target used to develop the macro implementation.
		.testTarget(name: "M3DataMacrosTests", dependencies: [
			"M3DataMacros",
			.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
		]),
    ]
)
