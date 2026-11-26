import Foundation
import ProviderChatSection
import ProviderConversation
import ProviderConversationState
import ProviderDeveloperMode
import ProviderMessage

/// 新版 PluginMessageList 的服务容器。
///
/// 旧版 ViewModel 直接持有 `KernelLumi` 并访问 `kernel.messageManager` 等；
/// 新版改为在插件 `onBoot` 时解析全部 Provider，经 `Capabilities/` 收窄为
/// 最小能力协议后集中在这里传给各视图模型。
/// 全部为可选，允许部分 Provider 尚未注入时优雅降级（与旧版一致）。
@MainActor
struct MessageListServices {
    let conversations: (any MessageListConversationCapability)?
    let conversationState: (any MessageListConversationStateCapability)?
    let developerModeState: DeveloperModeStateViewModel
    let messages: (any MessageListMessageCapability)?
    let rendering: (any MessageListRenderingCapability)?
    let streaming: (any MessageListStreamingCapability)?
    let toolManager: (any MessageListToolManagerCapability)?
    let agentTurn: (any MessageListAgentLoopCapability)?
    let promptSuggestions: (any MessageListPromptSuggestionCapability)?
    let promptSuggestionExecutor: (any MessageListPromptSuggestionExecutorCapability)?
    let project: (any MessageListProjectCapability)?
    let toolbar: (any MessageListToolbarCapability)?
    let chat: (any MessageListChatSectionCapability)?
    var selectedConversationID: UUID? {
        conversations?.selectedConversationID
    }

    var activeChatContext: ChatContext? {
        chat?.activeContext
    }

    func verbosity(for conversationID: UUID?) -> ResponseVerbosity {
        conversations?.verbosity(for: conversationID) ?? .defaultVerbosity
    }

    func activityMessage(for conversationID: UUID?) -> Message? {
        guard let conversationID,
              let conversationState else { return nil }
        let state = conversationState.state(for: conversationID)
        guard let activity = state.activity else { return nil }
        let content: String
        switch activity {
        case .sending: content = pluginLocalization.string("Sending message…")
        case .thinking: content = pluginLocalization.string("Thinking…")
        case .executingTool:
            if let description = state.jobActivity.recentJobDescription,
               state.jobActivity.runningJobCount > 0 {
                content = String(format: pluginLocalization.string("Executing %@…"), description)
            } else {
                content = pluginLocalization.string("Executing tool…")
            }
        case .waitingForUser: content = pluginLocalization.string("Waiting for your input…")
        }
        return Message(conversationID: conversationID, role: .status, content: content)
    }

}
