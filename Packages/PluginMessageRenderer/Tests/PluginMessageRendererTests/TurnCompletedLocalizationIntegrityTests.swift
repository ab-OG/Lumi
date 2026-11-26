import Foundation
import Testing
@testable import PluginMessageRenderer

/// 回合完成分隔线（TurnCompletedMessageView）文案的本地化契约。
///
/// 该视图曾直接硬编码中文「结束」「耗时 X」，英文界面下依然显示中文。
/// 迁移为英文源 key 后，这里兜住目录契约：key 为英文原文、中文翻译保留、
/// 格式符占位在各语言间一致。
@Suite("回合完成分隔线本地化")
struct TurnCompletedLocalizationIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]

    @Test("Turn complete / Duration%@ 以英文源 key 登记，中文翻译保留")
    func turnCompletedKeysAreEnglishSourced() throws {
        let expected: [String: String] = [
            "Turn complete": "结束",
            "Duration %@": "耗时 %@",
        ]
        let catalog = try Self.loadCatalog()
        for (key, zhHans) in expected {
            let entry = try #require(catalog[key], "「\(key)」未进入 xcstrings，但 TurnCompletedMessageView 已使用")
            #expect(entry.localizations["en"] == key, "「\(key)」的 en 值应与 key 一致")
            #expect(entry.localizations["zh-Hans"] == zhHans, "「\(key)」的简体中文译文不符")
            let missing = Self.requiredLanguages.filter { catalog[key]?.localizations[$0] == nil }
            #expect(missing.isEmpty, "「\(key)」缺少语言：\(missing.sorted().joined(separator: ", "))")
        }
    }

    @Test("Duration %@ 各语言占位符数量一致")
    func placeholderConsistent() throws {
        let entry = try #require(try Self.loadCatalog()["Duration %@"])
        for language in Self.requiredLanguages {
            let value = try #require(entry.localizations[language], "\(language) 缺翻译")
            #expect(value.components(separatedBy: "%").count - 1 == 1, "\(language) 占位符数量应为 1")
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
        // Tests/PluginMessageRendererTests/<file> → 包根
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
