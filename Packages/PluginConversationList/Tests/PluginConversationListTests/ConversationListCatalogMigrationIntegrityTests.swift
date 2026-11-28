import Foundation
import Testing
@testable import PluginConversationList

/// PluginConversationList 目录迁移的契约（5 项 gate 发现清零后的回归兜底）。
///
/// 历史问题：目录 key 是中文且无任何译文，核心 UI（列表、工具栏、空/错态、
/// 相对时间）硬编码中文。本套断言迁移后的硬性条件：所有可见文案 key 以英文
/// 为源、5 种语言齐全、旧中文 key 不再存在、占位符各语言一致、计数与相对
/// 时间标签提供单/复数两个 key。
@Suite("PluginConversationList 目录迁移完整性")
struct ConversationListCatalogMigrationIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]

    private static let migratedKeys = [
        // 原 catalog 中文 key（gate 发现；'删除' 并入既有 'Delete' key）
        "All Projects",
        "Could not load conversations",
        "No conversations",
        "View conversation statistics",
        // 原硬编码中文文案
        "Project conversations (%@)",
        "All project conversations",
        "Current project",
        "Daily conversation count",
        "Conversation",
        "Just now",
    ]

    /// 计数/相对时间标签必须成对提供单/复数 key。
    private static let countKeyPairs = [
        ["%lld conversation", "%lld conversations"],
        ["%lld minute ago", "%lld minutes ago"],
        ["%lld hour ago", "%lld hours ago"],
        ["%lld day ago", "%lld days ago"],
    ]

    @Test("迁移 key 以英文为源且五种语言齐全")
    func migratedKeysAreEnglishSourcedAndComplete() throws {
        let catalog = try Self.loadCatalog()
        for key in Self.migratedKeys {
            let entry = try #require(catalog[key], "「\(key)」未进入 xcstrings，但源码已使用")
            #expect(entry.localizations["en"] == key, "「\(key)」en 值应与 key 一致")
            let missing = Self.requiredLanguages.filter { entry.localizations[$0] == nil }
            #expect(missing.isEmpty, "「\(key)」缺少语言：\(missing.sorted().joined(separator: ", "))")
            let chinese = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
            #expect(entry.localizations["en"]!.rangeOfCharacter(from: chinese) == nil, "「\(key)」en 值不应包含中文")
        }
    }

    @Test("既有共享 key 保留全部语言（Delete / %lld conversations）")
    func sharedKeysKeepAllLocales() throws {
        let catalog = try Self.loadCatalog()
        for key in ["Delete", "%lld conversations"] {
            let entry = try #require(catalog[key], "「\(key)」应保留在目录中")
            let missing = Self.requiredLanguages.filter { entry.localizations[$0] == nil }
            #expect(missing.isEmpty, "「\(key)」缺少语言：\(missing.sorted().joined(separator: ", "))")
        }
        #expect(catalog["Delete"]?.localizations["zh-Hans"] == "删除")
    }

    @Test("计数标签提供单数与复数两个 key")
    func countKeysProvideSingularAndPlural() throws {
        let catalog = try Self.loadCatalog()
        for pair in Self.countKeyPairs {
            for key in pair {
                #expect(catalog[key] != nil, "计数 key「\(key)」应存在于目录")
            }
        }
        #expect(pluginLocalization.count("conv-singular", "conv-plural", for: 1) == "conv-singular")
        #expect(pluginLocalization.count("conv-singular", "conv-plural", for: 0) == "conv-plural")
        #expect(pluginLocalization.count("conv-singular", "conv-plural", for: 2) == "conv-plural")
    }

    @Test("旧中文 source key 不再出现在目录中")
    func legacyChineseKeysRemoved() throws {
        let catalog = try Self.loadCatalog()
        let legacy = ["删除", "所有项目", "无法加载对话", "暂无对话", "查看对话统计"]
        for key in legacy {
            #expect(catalog[key] == nil, "旧中文 key「\(key)」应已从目录移除")
        }
    }

    @Test("带占位符的迁移 key 各语言占位符数量一致")
    func placeholdersConsistent() throws {
        let catalog = try Self.loadCatalog()
        for key in Self.migratedKeys + Self.countKeyPairs.flatMap({ $0 }) where key.contains("%") {
            guard let entry = catalog[key], let en = entry.localizations["en"] else { continue }
            let count = en.components(separatedBy: "%").count - 1
            for language in Self.requiredLanguages {
                guard let translated = entry.localizations[language] else { continue }
                #expect(
                    translated.components(separatedBy: "%").count - 1 == count,
                    "「\(key)」在 \(language) 的占位符数量与 en 不一致"
                )
            }
        }
    }

    // MARK: - Helpers

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

    private static func catalogURL() -> URL? {
        var directory = URL(fileURLWithPath: #filePath)
        // Tests/PluginConversationListTests/<file> → 包根
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
