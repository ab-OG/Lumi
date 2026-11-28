import Foundation
import Testing
@testable import DatabaseManagerPlugin

/// PluginDatabaseManager 目录补全的契约（27 项 gate 发现清零后的回归兜底）。
///
/// 历史问题：结构面板/连接表单的 25 个英文 key 缺 `en` 值（en 是源语言却
/// 回退 key 显示）、`Index Type` 的 en 值错写成 'Type'、`No tables` 被
/// DEBUG 预览引用却不在目录中。本套断言补全后的硬性条件：
/// 这些 key 以英文为源（en ≡ key）、5 种语言齐全、占位符各语言一致。
@Suite("PluginDatabaseManager 目录补全完整性")
struct DatabaseManagerCatalogIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]

    /// 补全 en 后的关键可见文案（en 源 key；zh 译文保持原样未动）。
    private static let completedKeys = [
        "Add Column",
        "Add Index",
        "Allow NULL",
        "Apply Structure Changes",
        "Columns",
        "DDL is not available for this object.",
        "Data Type",
        "Default SQL Expression",
        "Drop Column…",
        "Drop Index…",
        "Index Name",
        "Index Type",
        "Loading structure…",
        "Name",
        "No items",
        "No tables",
        "OK",
        "Open a table or view to inspect its structure.",
        "Rename Column",
        "Rename…",
        "Review the generated DDL before changing the database.",
        "SSL / TLS",
        "Some database engines auto-commit DDL statements.",
        "Structure Change Error",
        "Structure Section",
        "This change drops data and cannot be undone by Lumi.",
        "Unique Index",
    ]

    /// 既有 zh 译文必须原样保留（抽查代表 key）。
    private static let preservedChineseSamples = [
        "Add Column": "添加列",
        "Index Type": "类型",
        "Name": "名称",
        "OK": "确定",
    ]

    @Test("补全 key 以英文为源且五种语言齐全")
    func completedKeysAreEnglishSourcedAndComplete() throws {
        let catalog = try Self.loadCatalog()
        for key in Self.completedKeys {
            let entry = try #require(catalog[key], "「\(key)」未进入 xcstrings，但源码已使用")
            #expect(entry.localizations["en"] == key, "「\(key)」en 值应与 key 一致")
            let missing = Self.requiredLanguages.filter { entry.localizations[$0] == nil }
            #expect(missing.isEmpty, "「\(key)」缺少语言：\(missing.sorted().joined(separator: ", "))")
            let chinese = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")
            #expect(entry.localizations["en"]!.rangeOfCharacter(from: chinese) == nil, "「\(key)」en 值不应包含中文")
        }
    }

    @Test("既有中文译文不被覆盖")
    func existingChineseTranslationsPreserved() throws {
        let catalog = try Self.loadCatalog()
        for (key, expected) in Self.preservedChineseSamples {
            let actual = try #require(catalog[key]?.localizations["zh-Hans"], "「\(key)」应保留 zh-Hans 译文")
            #expect(actual == expected, "「\(key)」的 zh-Hans 译文被意外改动")
        }
    }

    @Test("带占位符的 key 各语言占位符数量一致")
    func placeholdersConsistent() throws {
        let catalog = try Self.loadCatalog()
        for key in Self.completedKeys where key.contains("%") {
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
        // Tests/<file>（平铺）→ 包根
        for _ in 0..<2 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
