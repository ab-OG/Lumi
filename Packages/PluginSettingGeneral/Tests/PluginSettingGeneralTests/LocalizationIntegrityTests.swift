import Foundation
import Testing
@testable import PluginSettingGeneral

/// 通用设置页的英文文案契约。
///
/// 本包以英文为源语言：调用侧统一写 `pluginLocalization.string("<English>")`
/// （计数文案用 `pluginLocalization.count("<singular>", "<plural>", for:)`），
/// 中文在 xcstrings 中作为翻译提供。单测无法渲染 SwiftUI 文案，
/// 只能读 xcstrings 本身兜底：key 必须是英文、必须有非空 en 值和 zh-Hans 值。
@Suite("本地化资源完整性")
struct LocalizationIntegrityTests {
    /// 通用设置页全部用户可见 key（含单复数成对的 key）。
    private static let userFacingKeys = [
        "Also delete API keys, passwords, and credentials from the Keychain",
        "Also move the Lumi app to the Trash",
        "Build",
        "Calculating…",
        "Cancel",
        "Check for Updates",
        "Check...",
        "Checking Lumi data…",
        "Checking...",
        "Choose where to save the diagnostics log",
        "Clear Data and Quit",
        "Clearing plugin data, preferences, extension data, and credentials.",
        "Close",
        "Command Line Tool",
        "Completely Uninstall Lumi",
        "Delete Permanently and Uninstall",
        "Diagnostic Logs",
        "Diagnostics log service unavailable.",
        "Export",
        "Export Logs",
        "Export cancelled.",
        "Export failed: %@",
        "Exporting…",
        "General",
        "General Settings",
        "Get preview builds from the pre branch. They may contain unfixed issues.",
        "Get stable builds from the main branch.",
        "Install",
        "Installation failed: %@",
        "Installed at %@",
        "Logs exported: %@",
        "Lumi",
        "Lumi data has been cleared; the app will quit shortly.",
        "Lumi has been removed from your Mac and moved to the Trash.",
        "Name",
        "No user manual yet.",
        "Not Installed",
        "Open",
        "Open Database Folder",
        "Package recent logs to attach to problem reports.",
        "Plus %lld more item, processed together after confirmation.",
        "Plus %lld more items, processed together after confirmation.",
        "Preview",
        "Processing %lld Lumi data item, totaling %@.",
        "Processing %lld Lumi data items, totaling %@.",
        "Registers the General settings entry with app info, website and updates.",
        "Remove Lumi's plugin data, preferences, extension data, and optional credentials.",
        "Settings...",
        "Some data could not be cleared; the app was not removed.",
        "Some data could not be cleared; the app was not removed:\\n",
        "Stable",
        "Storage Size",
        "Storage service unavailable",
        "The current options delete nothing.",
        "The lumi command is ready to use.",
        "This action cannot be undone",
        "This permanently deletes data Lumi stored itself. Your projects, source code, and exported files are not deleted.",
        "Uninstall",
        "Uninstall Complete",
        "Uninstall Incomplete",
        "Uninstall Lumi",
        "Uninstall failed: %@",
        "Uninstall service unavailable.",
        "Uninstalling Lumi…",
        "Uninstalling…",
        "Update Channel",
        "Updates",
        "Usage guides for each feature.",
        "User Manual",
        "Version",
        "second until automatic quit",
        "seconds until automatic quit",
    ]

    /// 英文需要区分单复数的计数文案对：(singular, plural)。
    private static let countPairs: [(singular: String, plural: String)] = [
        (
            "Processing %lld Lumi data item, totaling %@.",
            "Processing %lld Lumi data items, totaling %@."
        ),
        (
            "Plus %lld more item, processed together after confirmation.",
            "Plus %lld more items, processed together after confirmation."
        ),
        (
            "second until automatic quit",
            "seconds until automatic quit"
        ),
    ]

    @Test("通用设置页的可见文案都是英文 key 且有 en 与 zh-Hans")
    func userFacingKeysAreEnglish() throws {
        let catalog = try Self.loadCatalog()
        let chinese = CharacterSet(charactersIn: "\u{4E00}"..."\u{9FFF}")

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
            #expect(
                english == key,
                "「\(key)」的 en 翻译应与 key 一致（en 为源语言），实际为「\(english)」"
            )
            #expect(
                key.rangeOfCharacter(from: chinese) == nil,
                "「\(key)」仍包含中文字符，英文界面会显示原文"
            )
            let simplified = try #require(
                entry["zh-Hans"],
                "「\(key)」缺少 zh-Hans 翻译，中文界面会显示英文"
            )
            #expect(!simplified.isEmpty, "「\(key)」的 zh-Hans 翻译为空")
        }
    }

    @Test("计数文案的单复数 key 都存在且英文名词形式不同")
    func countPairsAreComplete() throws {
        let catalog = try Self.loadCatalog()

        for pair in Self.countPairs {
            for key in [pair.singular, pair.plural] {
                let entry = try #require(
                    catalog[key],
                    "计数文案 key「\(key)」未出现在 xcstrings 中"
                )
                let english = try #require(entry["en"], "计数文案 key「\(key)」缺少 en")
                let simplified = try #require(entry["zh-Hans"], "计数文案 key「\(key)」缺少 zh-Hans")
                #expect(!english.isEmpty && !simplified.isEmpty)
            }
            #expect(
                pair.singular != pair.plural,
                "计数文案单复数 key 不应相同：「\(pair.singular)」"
            )
        }
    }

    // MARK: - Helpers

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
        // Tests/PluginSettingGeneralTests/<file> → 包根
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
