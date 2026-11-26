import Foundation

/// 命令风险等级（纯逻辑部分，UI 扩展在 LumiUI）
///
/// 用于评估工具调用的风险级别，决定是否需要用户授权。
/// `iconName` 和 `iconColor` 等 UI 属性在 `LumiUI` 的 extension 中定义。
public enum CommandRiskLevel: String, Codable, Sendable {
    case safe
    case low
    case medium
    case high

    /// 是否需要用户授权
    public var requiresPermission: Bool {
        switch self {
        case .safe: return false
        case .low: return false
        case .medium: return false
        case .high: return true
        }
    }

    /// 显示名称
    public var displayName: String {
        switch self {
        case .safe: return pluginLocalization.string("Safe")
        case .low: return pluginLocalization.string("Low risk")
        case .medium: return pluginLocalization.string("Medium risk")
        case .high: return pluginLocalization.string("High risk")
        }
    }

    /// 风险原因说明
    public var reason: String? {
        switch self {
        case .safe: return nil
        case .low: return pluginLocalization.string("This operation only reads information and does not modify files")
        case .medium: return pluginLocalization.string("This operation may modify files or access the network")
        case .high: return pluginLocalization.string("This operation may cause data loss or system changes")
        }
    }
}
