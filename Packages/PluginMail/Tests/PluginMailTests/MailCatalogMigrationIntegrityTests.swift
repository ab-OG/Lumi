import Foundation
import Testing
@testable import PluginMail

/// PluginMail 目录迁移的契约（24 项 gate 发现清零后的回归兜底）。
///
/// 历史问题：目录 key 是中文且无任何译文（en 是源语言却回退显示中文 key），
/// 大量可见文案绕过 `pluginLocalization` 直接硬编码中文。本套断言迁移后的
/// 硬性条件：所有可见文案 key 以英文为源、5 种语言齐全、旧中文 key 不再存在、
/// 占位符各语言一致、计数标签提供单/复数两个 key。
@Suite("PluginMail 目录迁移完整性")
struct MailCatalogMigrationIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]

    /// 迁移后的关键可见文案（en 源 key，覆盖原 24 项 gate 发现 + 原硬编码文案）。
    private static let migratedKeys = [
        // 原 catalog 中文 key（gate 发现）
        "%lld attachments",
        "IMAP Server",
        "SMTP Server",
        "Remote images and styles are blocked for privacy.",
        "From",
        "Drag attachments into the window to attach them.",
        "Search mail",
        "To",
        "Display Name (Optional)",
        "Provider",
        "Loading message body…",
        "Syncing…",
        "No results for “%@”",
        "No Mail",
        "Login Username",
        "Port must be between 1 and 65535.",
        "Draft saved %@",
        "Go to Settings → Mail to add an IMAP/SMTP account.",
        "No Mail Accounts Yet",
        "No mail accounts yet. Click Add Account below to get started.",
        "Select a message to read it",
        "Email Address",
        "Attachments (%lld)",
        // 原硬编码中文文案
        "IMAP/SMTP mail client: multiple accounts, three-pane workspace, composing, and Agent tools.",
        "IMAP/SMTP accounts: connection, composing, search, and Agent tools.",
        "Accounts",
        "Test",
        "Edit",
        "Delete",
        "Add Account",
        "Edit Account",
        "Account Details",
        "Password / App Password",
        "App-specific password or auth code",
        "Servers",
        "IMAP Port",
        "SMTP Port",
        "Require TLS",
        "Testing…",
        "Test Connection",
        "Cancel",
        "Save",
        "Enter an email address and password/auth code first.",
        "Connection succeeded: authentication passed.",
        "Connection failed: %@",
        "Email address cannot be empty.",
        "Enter a password/auth code.",
        "IMAP and SMTP servers cannot be empty.",
        "IMAP and SMTP ports must be between 1 and 65535.",
        "No password found for this account. Edit it and save a password first.",
        "Close",
        "Compose",
        "Reply",
        "Forward",
        "Cc",
        "Subject",
        "(optional)",
        "Sending…",
        "Send",
        "(No Subject)",
        "Unknown Sender",
        "(No body)",
        "Load Remote Content",
        "Unknown",
        "Recipients cannot be empty.",
        "Loading folders",
        "Syncing %@",
        "Reading message",
        "%@ failed: %@",
        "Failed to send: %@",
        "QQ Mail",
        "NetEase 163",
        "Custom",
    ]

    /// 计数标签必须成对提供单/复数 key。
    private static let countKeyPairs = [
        ["%lld attachment", "%lld attachments"],
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

    @Test("计数标签提供单数与复数两个 key")
    func countKeysProvideSingularAndPlural() throws {
        let catalog = try Self.loadCatalog()
        for pair in Self.countKeyPairs {
            for key in pair {
                #expect(catalog[key] != nil, "计数 key「\(key)」应存在于目录")
            }
        }
        #expect(pluginLocalization.count("mail-singular", "mail-plural", for: 1) == "mail-singular")
        #expect(pluginLocalization.count("mail-singular", "mail-plural", for: 0) == "mail-plural")
        #expect(pluginLocalization.count("mail-singular", "mail-plural", for: 2) == "mail-plural")
    }

    @Test("旧中文 source key 不再出现在目录中")
    func legacyChineseKeysRemoved() throws {
        let catalog = try Self.loadCatalog()
        let legacy = [
            "%lld 个附件", "IMAP 服务器", "SMTP 服务器",
            "为保护隐私，已拦截远程图片和样式。", "发件人", "拖入附件到窗口，或点击添加",
            "搜索邮件", "收件人", "显示名称（可选）", "服务商", "正在加载正文…",
            "正在同步…", "没有匹配「%@」的结果", "没有邮件", "登录用户名",
            "端口必须在 1–65535 之间。", "草稿已保存 %@",
            "请到「设置 → 邮件」添加 IMAP/SMTP 账户。", "还没有邮件账户",
            "还没有邮件账户。点击下方「添加账户」开始配置。", "选择一封邮件查看内容",
            "邮件", "邮箱地址", "附件（%lld）",
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
        // Tests/PluginMailTests/<file> → 包根
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
