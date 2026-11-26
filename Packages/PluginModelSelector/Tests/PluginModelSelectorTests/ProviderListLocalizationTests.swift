import Foundation
import Testing
@testable import PluginModelSelector

@Suite("ProviderListLocalization")
struct ProviderListLocalizationTests {
    /// 回归 #906：中转站分组标题必须经过插件本地化解析，而不是写死中文字面量。
    ///
    /// 用注入的替身解析器断言「文案确实来自解析器」，因为真实解析结果取决于
    /// 宿主首选语言，无法在 CI 上给出与语言无关的期望值。
    @Test("中转站分组标题经过注入的本地化解析（回归 #906）")
    func relaySectionTitleUsesInjectedLocalization() {
        let resolve: (String) -> String = { "localized:\($0)" }

        #expect(
            ProviderListLocalization.relaySectionTitle(resolve: resolve) == "localized:Relay"
        )
    }

    /// 回归 #906：词条必须在编译产物里对每种受支持语言都有译文，
    /// 否则英文界面会显示中文，或中文界面回落成英文 key。
    @Test("中转站分组标题在所有规范语言下都有译文（回归 #906）")
    func relaySectionTitleHasTranslationsInCompiledBundle() throws {
        let expected: [String: String] = [
            "en": "Relay",
            "zh-Hans": "中转站",
            "zh-Hant": "中轉站",
            "zh-HK": "中轉站",
            "zh-TW": "中轉站",
        ]

        for (language, translation) in expected {
            let table = try Self.compiledStrings(language: language)
            #expect(
                table["Relay"] == translation,
                "\(language) 下 Relay 译文缺失或不符，中转站分组标题会回退到其它语言"
            )
        }
    }

// MARK: - Provider model-count label（回归："1 models"）

    /// 回归 "1 models"：count 1 用单数 key "1 model"，其余用 "%lld models"。
    /// 解析器注入，期望值与宿主语言无关。
    @Test("模型计数：count 1 单数，其余复数（回归 1 models）")
    func modelCountLabelSingularAndPlural() throws {
        let cases: [(count: Int, expected: String)] = [
            (0, "key:0 models"),
            (1, "key:1 model"),
            (2, "key:2 models"),
            (23, "key:23 models"),
        ]
        for testCase in cases {
            let resolved = ProviderListItem.modelsCountText(
                resolve: { "key:\($0)" },
                count: testCase.count
            )
            #expect(
                resolved == testCase.expected,
                "count \(testCase.count) 应生成「\(testCase.expected)」，实际「\(resolved)」"
            )
        }
    }

    /// 计数 key 对在编译产物中每种语言都要有译文，否则退化成 key 本身。
    @Test("模型计数 key 在所有规范语言下都有译文")
    func modelCountKeysHaveAllTranslations() throws {
        let expected: [String: [String: String]] = [
            "1 model": [
                "en": "1 model",
                "zh-Hans": "1 个模型",
                "zh-Hant": "1 個模型",
                "zh-HK": "1 個模型",
                "zh-TW": "1 個模型",
            ],
            "%lld models": [
                "en": "%lld models",
                "zh-Hans": "%lld 个模型",
                "zh-Hant": "%lld 個模型",
                "zh-HK": "%lld 個模型",
                "zh-TW": "%lld 個模型",
            ],
        ]
        for (key, translations) in expected {
            for (language, translation) in translations {
                let table = try Self.compiledStrings(language: language)
                #expect(
                    table[key] == translation,
                    "\(language) 下「\(key)」译文缺失或不符，计数标签会回退到 key"
                )
            }
        }
    }

    private static func compiledStrings(language: String) throws -> [String: String] {
        let bundle = pluginLocalization.bundle
        let lprojPath = try #require(bundle.path(forResource: language, ofType: "lproj"))
        let stringsPath = (lprojPath as NSString).appendingPathComponent("Localizable.strings")
        return try #require(NSDictionary(contentsOfFile: stringsPath) as? [String: String])
    }
}
