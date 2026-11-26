import Foundation
import Testing
@testable import PluginLLMProviderSettings

/// 供应商设置页的英文文案契约。
///
/// 本包以英文为源语言：调用侧统一写 `pluginLocalization.string("<English>")`，
/// 中文及其他语言在 xcstrings 中作为翻译提供。这些 key 都会直接上屏（包含
/// `AppSettingSection` / `AppSettingRow` / `AppButton` 等只接受 String 的组件），
/// 所以单测无法渲染 SwiftUI 文案，只能读 xcstrings 本身兜底：
/// key 必须是英文、必须有非空 en 值。
@Suite("本地化资源完整性")
struct LocalizationIntegrityTests {
    /// #880 报告及本轮修复过的全部用户可见 key。
    private static let userFacingKeys = [
        "API Key",
        "Configure access credentials",
        "Enter API Key",
        "Actions",
        "No API key saved",
        "API key saved",
        "Hide API Key",
        "Show API Key",
        "Copy API Key",
        "Copied",
        "Save",
        "Delete",
        "Error",
        "Available Models",
        "Context %@",
        "Vision",
        "Current",
        "Edit",
        "Delete custom provider?",
        "This removes the provider configuration and its API key.",
        "Visit Website",
        "Cancel",
        "%lld models",
        "%lld model",
        "%lld local providers",
        "%lld local provider",
        "%lld cloud providers",
        "%lld cloud provider",
        "Add Provider",
        "No providers found",
        "Select a provider",
        "Search providers",
        "Add Cloud Provider",
        "Edit Cloud Provider",
        "Configure a compatible API endpoint and model list",
        "General",
        "Provider Name",
        "Description (optional)",
        "Website (optional)",
        "Connection",
        "Models",
        "Model IDs (one per line)",
        "OpenAI Compatible",
        "Anthropic Compatible",
        "Model Downloads",
        "Cache Usage",
        "Download Speed Limit",
        "Open",
        "No Limit",
        "Custom",
        "Downloading...",
        "Paused",
        "Downloaded",
        "Pause Download",
        "Resume Download",
        "Cancel Download",
        "Download",
    ]

    @Test("供应商设置页的可见文案都是英文 key 且有 en 与 zh-Hans")
    func userFacingKeysAreEnglish() throws {
        let catalog = try Self.loadCatalog()

        for key in Self.userFacingKeys {
            let entry = try #require(
                catalog[key],
                "「\(key)」未出现在 xcstrings 中，但代码里已作为可见文案使用"
            )
            let english = try #require(
                entry["en"],
                "「\(key)」缺少 en 翻译，英文界面会把 key 直接显示出来"
            )
            #expect(!english.isEmpty, "「\(key)」的 en 翻译为空")
            // 英文是源语言：key 本身就是英文文案，禁止再引入中文 key。
            #expect(
                english == key,
                "「\(key)」的 en 翻译应与 key 一致（en 为源语言），实际为「\(english)」"
            )
            #expect(
                key.rangeOfCharacter(from: Self.chineseCharacters) == nil,
                "「\(key)」仍包含中文字符，英文界面会显示原文"
            )
        }
    }

    // MARK: - Helpers

    /// 用于校验 key 不再包含中文的字符集。
    private static let chineseCharacters = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")

    private static func loadCatalog() throws -> [String: [String: String]] {
        let url = try #require(
            catalogURL(),
            "找不到本包的 xcstrings 资源文件"
        )
        let data = try Data(contentsOf: url)
        let root = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any],
            "xcstrings 根节点不是 JSON 对象"
        )
        let strings = try #require(root["strings"] as? [String: Any], "xcstrings 缺少 strings 节点")

        var result: [String: [String: String]] = [:]
        for (key, value) in strings {
            guard let value = value as? [String: Any],
                  let raw = value["localizations"] as? [String: Any] else {
                result[key] = [:]
                continue
            }
            var localizations: [String: String] = [:]
            for (language, unit) in raw {
                guard let unit = unit as? [String: Any],
                      let stringUnit = unit["stringUnit"] as? [String: Any],
                      let text = stringUnit["value"] as? String else { continue }
                localizations[language] = text
            }
            result[key] = localizations
        }
        return result
    }

    /// 从包目录定位 xcstrings（测试运行时的当前目录不可依赖）。
    private static func catalogURL() -> URL? {
        var directory = URL(fileURLWithPath: #filePath)
        // Tests/PluginLLMProviderSettingsTests/<file> → 包根
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
