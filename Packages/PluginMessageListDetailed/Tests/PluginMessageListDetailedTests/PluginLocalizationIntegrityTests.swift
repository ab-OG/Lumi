import Foundation
import Testing
@testable import PluginMessageListDetailed

/// 本地化资源完整性（回归：状态栏曾以中文作为 en 值）。
///
/// `MessageListServices.activityMessage` 的 4 类状态文案曾以 `status.*` 为 key、
/// 中文作为 en 缺省值，英文界面下用户看到的是中文。迁移为英文源 key 后，
/// 用这些断言兜住：key 必须是英文原文，且 4 种语言翻译齐全。
/// （gate 脚本 `Scripts/check-localization-keys.py` 检查源码与目录的一致性；
///  这里从 xcstrings 本身断言契约，二者互补。）
@Suite("状态文案本地化完整性")
struct PluginLocalizationIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-HK", "zh-TW"]

    /// 状态键 → 期望的中文（简体）译文。
    private static let statusKeys: [String: String] = [
        "Sending message…": "正在发送消息…",
        "Thinking…": "正在思考…",
        "Executing tool…": "正在执行工具…",
        "Executing %@…": "正在执行 %@…",
        "Waiting for your input…": "等待你的输入…",
    ]

    @Test("状态文案以英文源 key 登记，四种语言齐全")
    func statusKeysAreEnglishSourcedAndFullyLocalized() throws {
        let catalog = try Self.loadCatalog()
        for (key, zhHans) in Self.statusKeys {
            let entry = try #require(catalog[key], "「\(key)」未进入 xcstrings，但源码已使用")
            #expect(entry.localizations["en"] == key, "「\(key)」的 en 值应与 key 一致（英文源）")
            #expect(entry.localizations["zh-Hans"] == zhHans, "「\(key)」的简体中文译文不符")
            let languages = Set(entry.localizations.keys)
            let missing = Self.requiredLanguages.filter { !languages.contains($0) }
            #expect(missing.isEmpty, "「\(key)」缺少语言：\(missing.sorted().joined(separator: ", "))")
        }
    }

    @Test("旧的中文 source key 不再出现在目录中")
    func legacyChineseStatusKeysRemoved() throws {
        let catalog = try Self.loadCatalog()
        for legacy in ["status.sending", "status.thinking", "status.executing-tool", "status.waiting-for-user"] {
            #expect(catalog[legacy] == nil, "旧 key「\(legacy)」应已从目录移除")
        }
    }

    @Test("带占位符的状态文案各语言占位符数量一致")
    func placeholdersAreConsistentAcrossLanguages() throws {
        let catalog = try Self.loadCatalog()
        for (key, entry) in Self.statusKeys {
            guard let source = catalog[key]?.localizations["en"] else { continue }
            let count = Self.placeholderCount(source)
            for language in Self.requiredLanguages {
                guard let translated = catalog[key]?.localizations[language] else { continue }
                #expect(
                    Self.placeholderCount(translated) == count,
                    "「\(key)」在 \(language) 的占位符数量与 en 不一致"
                )
            }
        }
    }

    // MARK: - Helpers

    private static func placeholderCount(_ text: String) -> Int {
        text.components(separatedBy: "%").count - 1
    }

    private struct CatalogEntry {
        var localizations: [String: String]
    }

    private static func loadCatalog() throws -> [String: CatalogEntry] {
        let url = try #require(Self.catalogURL(), "找不到本包的 xcstrings 资源文件")
        let data = try Data(contentsOf: url)
        let value = try JSONSerialization.jsonObject(with: data)
        let root = try #require(value as? [String: Any], "xcstrings 根节点不是 JSON 对象")
        let strings = try #require(root["strings"] as? [String: Any], "xcstrings 缺少 strings 节点")

        var result: [String: CatalogEntry] = [:]
        for (key, value) in strings {
            guard let node = value as? [String: Any] else {
                result[key] = CatalogEntry(localizations: [:])
                continue
            }
            let raw = (node["localizations"] as? [String: Any]) ?? [:]
            var localizations: [String: String] = [:]
            for (language, unit) in raw {
                guard let unit = unit as? [String: Any],
                      let stringUnit = unit["stringUnit"] as? [String: Any],
                      let text = stringUnit["value"] as? String else { continue }
                localizations[language] = text
            }
            result[key] = CatalogEntry(localizations: localizations)
        }
        return result
    }

    /// 从包目录定位 xcstrings（测试运行时的当前目录不可依赖）。
    private static func catalogURL() -> URL? {
        var directory = URL(fileURLWithPath: #filePath)
        // Tests/PluginMessageListDetailedTests/<file> → 包根
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
