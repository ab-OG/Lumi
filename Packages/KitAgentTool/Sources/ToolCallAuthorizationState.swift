import Foundation

/// 单条工具调用的授权结果（存于 `ToolCall.authorizationState`，随 `toolCalls` 序列化）。
public enum ToolCallAuthorizationState: String, Codable, Sendable, Equatable, CaseIterable {
    /// 判定为无风险，可直接执行
    case noRisk
    /// 由策略自动批准（如标题栏「自动批准」）
    case autoApproved
    /// 用户明确同意
    case userApproved
    /// 用户明确拒绝
    case userRejected
    /// 尚未授权，等待用户或策略处理
    case pendingAuthorization

    /// 简短中文标签（用于 UI）
    public var displayName: String {
        switch self {
        case .noRisk: return pluginLocalization.string("No risk")
        case .autoApproved: return pluginLocalization.string("Auto-approved")
        case .userApproved: return pluginLocalization.string("User approved")
        case .userRejected: return pluginLocalization.string("User rejected")
        case .pendingAuthorization: return pluginLocalization.string("Pending authorization")
        }
    }

    /// 是否仍等待用户或策略处理（未同意也未拒绝）
    public var needsAuthorizationPrompt: Bool {
        self == .pendingAuthorization
    }
}
