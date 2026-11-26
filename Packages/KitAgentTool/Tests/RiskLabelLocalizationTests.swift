import Foundation
import Testing
@testable import KitAgentTool

/// 风险等级与授权状态标签的本地化契约。
///
/// 这些标签直接渲染在权限卡片与调用行上（并在 ToolInteractionPayload 的
/// riskLevelName 中传递），必须能中英双向解析，而不是回退成英文 key。
@Suite
struct RiskLabelLocalizationTests {
    private static let levelKeys: [(CommandRiskLevel, String)] = [
        (.safe, "安全"),
        (.low, "低风险"),
        (.medium, "中风险"),
        (.high, "高风险"),
    ]

    private static let levelReasons: [(CommandRiskLevel, String, String)] = [
        (.low, "This operation only reads information and does not modify files", "此操作只读取信息，不会修改文件"),
        (.medium, "This operation may modify files or access the network", "此操作可能修改文件或访问网络"),
        (.high, "This operation may cause data loss or system changes", "此操作可能造成数据丢失或系统更改"),
    ]

    private static let stateKeys: [(ToolCallAuthorizationState, String)] = [
        (.noRisk, "无风险"),
        (.autoApproved, "自动同意"),
        (.userApproved, "用户同意"),
        (.userRejected, "用户拒绝"),
        (.pendingAuthorization, "等待授权"),
    ]

    @Test("风险等级 displayName 在英文下是英文文案")
    func riskLevelDisplayNamesResolveInEnglish() {
        let en = Locale(identifier: "en")
        #expect(pluginLocalization.string("Safe", locale: en) == "Safe")
        #expect(pluginLocalization.string("Low risk", locale: en) == "Low risk")
        #expect(pluginLocalization.string("Medium risk", locale: en) == "Medium risk")
        #expect(pluginLocalization.string("High risk", locale: en) == "High risk")
    }

    @Test("风险等级 displayName 在简体中文下是中文文案")
    func riskLevelDisplayNamesResolveInSimplifiedChinese() {
        let zh = Locale(identifier: "zh-Hans")
        for (level, expected) in Self.levelKeys {
            #expect(pluginLocalization.string(expectedEnglishKey(level), locale: zh) == expected)
        }
    }

    @Test("风险原因在英文与简体中文下都能解析")
    func riskReasonsResolveInBothLanguages() {
        let en = Locale(identifier: "en")
        let zh = Locale(identifier: "zh-Hans")
        for (_, enKey, zhExpected) in Self.levelReasons {
            #expect(pluginLocalization.string(enKey, locale: en) == enKey)
            #expect(pluginLocalization.string(enKey, locale: zh) == zhExpected)
        }
    }

    @Test("授权状态 displayName 在两种语言下都能解析")
    func authorizationStateDisplayNamesResolve() {
        let en = Locale(identifier: "en")
        let zh = Locale(identifier: "zh-Hans")
        #expect(pluginLocalization.string("No risk", locale: en) == "No risk")
        #expect(pluginLocalization.string("Auto-approved", locale: en) == "Auto-approved")
        #expect(pluginLocalization.string("User approved", locale: en) == "User approved")
        #expect(pluginLocalization.string("User rejected", locale: en) == "User rejected")
        #expect(pluginLocalization.string("Pending authorization", locale: en) == "Pending authorization")
        for (state, zhExpected) in Self.stateKeys {
            #expect(pluginLocalization.string(enKeyForState(state), locale: zh) == zhExpected)
        }
    }

    // MARK: - Helpers

    private func expectedEnglishKey(_ level: CommandRiskLevel) -> String {
        switch level {
        case .safe: return "Safe"
        case .low: return "Low risk"
        case .medium: return "Medium risk"
        case .high: return "High risk"
        }
    }

    private func enKeyForState(_ state: ToolCallAuthorizationState) -> String {
        switch state {
        case .noRisk: return "No risk"
        case .autoApproved: return "Auto-approved"
        case .userApproved: return "User approved"
        case .userRejected: return "User rejected"
        case .pendingAuthorization: return "Pending authorization"
        }
    }
}
