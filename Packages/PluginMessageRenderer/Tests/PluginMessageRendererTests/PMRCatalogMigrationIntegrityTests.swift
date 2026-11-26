import Foundation
import Testing
@testable import PluginMessageRenderer

/// PMR 目录迁移的契约（39 项 gate 发现清零后的回归兜底）。
///
/// 历史问题：目录 key 是中文（en 是源语言却存英文译文），部分可见文案
/// 甚至绕过 `pluginLocalization` 直接硬编码中文。本套断言迁移后的硬性条件：
/// 迁移 key 以英文为源、5 种语言齐全、旧中文 key 不再存在。
@Suite("PMR 目录迁移完整性")
struct PMRCatalogMigrationIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]

    /// 迁移后的关键可见文案（en 源 key）。
    private static let migratedKeys = [
        "Tool execution failed",
        "Tool Calls",
        "Thinking Process",
        "Execution Time",
        "View Tool Calls",
        "Querying results...",
        "Resend",
        "Resend this message",
        "Retry",
        "Retry this turn",
        "Message Details",
        "Call Parameters",
        "Call Results",
        "Copy message",
        "Core Message Renderer",
        "Collapse",
        "Expand",
        "Tool Output",
        "No output yet",
        "No new progress yet",
        "No error details",
        "No tool output yet",
        "View output",
        "Tap to view Goal auto-continuation details",
        "Goal auto-continuation stopped",
        "Goal auto-continuing",
        "Goal auto-continuing (%lld/%lld)",
        "Queued",
        "Running",
        "Waiting for user",
        "Cancelling",
        "Completed",
        "Failed",
        "Stopped",
        "Timed out",
        "Basic Information",
        "Message ID",
        "Conversation ID",
        "Role",
        "Created At",
        "Render Type",
        "Preferred Renderer",
        "Turn ID",
        "Error Flag",
        "Yes",
        "No",
        "Provider",
        "Performance",
        "Total Duration",
        "Time to First Token",
        "Streaming Duration",
        "Tool Association",
        "Error Details",
        "Raw Error",
        "Content Statistics",
        "Character Count",
        "Line Count",
        "Content is empty",
        "Thinking Content",
        "Image Attachment",
        "Tool Calls (%lld)",
        "Tool action %lld",
        "Run tool",
        "Arguments",
        "Result",
        "Waiting",
        "Succeeded",
        "%lld characters",
        "Model",
        "HTTP Status Code",
        "HTTP Response Body",
        "Tool Call ID",
        "Latency: %@",
        "First token: %@",
        "Streaming: %@",
        "Rendered as: %@",
        "Preferred: %@",
        "Elapsed: %@",
        "Output",
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

    @Test("旧中文 source key 不再出现在目录中")
    func legacyChineseKeysRemoved() throws {
        let catalog = try Self.loadCatalog()
        let legacy = [
            "工具执行失败", "工具调用", "思考过程", "执行耗时", "查看工具调用",
            "查询结果中...", "重发", "重新发送", "重新发送该消息", "重试", "重试该回合",
            "消息详情", "调用参数", "调用结果", "核心消息渲染器",
            "已提交：等待继续执行…", "无法解析工具审批请求", "耗时%@",
            "工具输出", "暂无新进度", "暂时没有输出", "查看输出",
            "点击查看 Goal 自动续跑详情", "正在加载工具结果…",
            "基本信息", "消息 ID", "会话 ID", "角色", "创建时间", "渲染类型",
            "期望渲染器", "轮次 ID", "错误标记", "是", "否", "供应商",
            "性能", "总耗时", "首 Token 延迟", "流式时长", "工具关联",
            "错误详情", "原始错误", "内容统计", "字符数", "行数", "内容为空",
            "思考内容", "图片附件", "工具调用 (%lld)", "工具操作 %lld", "执行工具",
            "参数", "结果", "等待中", "成功", "%lld 个字符", "HTTP 状态码",
            "HTTP 响应体", "耗时：%@", "首 Token 延迟：%@", "流式：%@",
            "渲染类型：%@", "首选：%@", "输出",
        ]
        for key in legacy {
            #expect(catalog[key] == nil, "旧中文 key「\(key)」应已从目录移除")
        }
    }

    @Test("带占位符的迁移 key 各语言占位符数量一致")
    func placeholdersConsistent() throws {
        let catalog = try Self.loadCatalog()
        for key in Self.migratedKeys where key.contains("%") {
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
