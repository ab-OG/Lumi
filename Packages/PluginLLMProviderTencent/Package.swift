// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PluginLLMProviderTencent",
    defaultLocalization: "en",
    platforms: [
        .macOS("13.1"),
        .iOS(.v17)
    ],
    products: [
        .library(name: "PluginLLMProviderTencent", targets: ["PluginLLMProviderTencent"]),
    ],
    dependencies: [
        .package(path: "../../Vendor/LumiKernel"),
        .package(path: "../ProviderLLMManager"),
        .package(path: "../KitLLM"),
    ],
    targets: [
        .target(
            name: "PluginLLMProviderTencent",
            dependencies: [
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderLLMManager", package: "ProviderLLMManager"),
                .product(name: "KitLLM", package: "KitLLM"),
            ],
            path: "Sources/PluginLLMProviderTencent",
            resources: [
                .process("../../Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "PluginLLMProviderTencentTests",
            dependencies: [
                "PluginLLMProviderTencent",
                .product(name: "KernelCore", package: "LumiKernel"),
                .product(name: "ProviderLLMManager", package: "ProviderLLMManager"),
            ],
            path: "Tests/PluginLLMProviderTencentTests"
        ),
    ]
)
