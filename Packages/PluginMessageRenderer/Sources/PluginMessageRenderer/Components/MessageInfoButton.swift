import KitAgentTool
import KernelCore
import LumiLocalizationKit
import LumiUI
import KitMarkdown
import ProviderConversation
import ProviderMessage
import ProviderMessageRendering
import ProviderMessageSender
import ProviderToolManager
import LumiUI
import SwiftUI

struct MessageInfoButton: View {
    @LumiTheme private var theme

    let message: Message
    @Binding var isPresented: Bool

    var body: some View {
        AppIconButton(
            systemImage: "info.circle",
            tint: isPresented ? theme.textPrimary : theme.textSecondary,
            size: .compact,
            isActive: isPresented
        ) {
            isPresented.toggle()
        }
        .help(pluginLocalization.string("Message Details"))
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            MessageInfoPopoverContent(message: message)
        }
    }
}

struct MessageInfoPopoverContent: View {
    @LumiTheme private var theme

    let message: Message

    private static let fullTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                infoSection(pluginLocalization.string("Basic Information")) {
                    infoRow(pluginLocalization.string("Message ID"), value: message.id.uuidString, isMono: true)
                    infoRow(pluginLocalization.string("Conversation ID"), value: message.conversationID.uuidString, isMono: true)
                    infoRow(pluginLocalization.string("Role"), value: message.role.rawValue)
                    infoRow(pluginLocalization.string("Created At"), value: Self.fullTimestampFormatter.string(from: message.createdAt))
                    infoRow(pluginLocalization.string("Render Type"), value: displayValue(message.renderKind))
                    if let preferred = message.preferredRendererID, !preferred.isEmpty {
                        infoRow(pluginLocalization.string("Preferred Renderer"), value: preferred, isMono: true)
                    }
                    if let turnID = message.turnID {
                        infoRow(pluginLocalization.string("Turn ID"), value: turnID.uuidString, isMono: true)
                    }
                    infoRow(
                        pluginLocalization.string("Error Flag"),
                        value: pluginLocalization.string(message.isError ? "Yes" : "No")
                    )
                }

                infoSection(pluginLocalization.string("Model")) {
                    infoRow(pluginLocalization.string("Provider"), value: displayValue(message.providerID))
                    infoRow(pluginLocalization.string("Model"), value: displayValue(message.modelName))
                }

                if message.latencyMs != nil || message.timeToFirstTokenMs != nil || message.streamingDurationMs != nil {
                    infoSection(pluginLocalization.string("Performance")) {
                        if let latency = message.latencyMs {
                            infoRow(pluginLocalization.string("Total Duration"), value: MessageViewHelpers.formatMilliseconds(latency))
                        }
                        if let ttft = message.timeToFirstTokenMs {
                            infoRow(pluginLocalization.string("Time to First Token"), value: MessageViewHelpers.formatMilliseconds(ttft))
                        }
                        if let streaming = message.streamingDurationMs {
                            infoRow(pluginLocalization.string("Streaming Duration"), value: MessageViewHelpers.formatMilliseconds(streaming))
                        }
                    }
                }

                if message.toolCallID != nil {
                    infoSection(pluginLocalization.string("Tool Association")) {
                        infoRow(pluginLocalization.string("Tool Call ID"), value: displayValue(message.toolCallID), isMono: true)
                    }
                }

                let hasHttpDetail = message.httpStatusCode != nil
                    || (message.httpBody?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
                if let detail = errorDetailSummary(for: message), !detail.isEmpty {
                    infoSection(pluginLocalization.string("Error Details")) {
                        infoMultilineRow(pluginLocalization.string("Raw Error"), value: detail)
                        httpDetailRows()
                    }
                } else if hasHttpDetail {
                    infoSection(pluginLocalization.string("Error Details")) {
                        httpDetailRows()
                    }
                }

                infoSection(pluginLocalization.string("Content Statistics")) {
                    infoRow(pluginLocalization.string("Character Count"), value: "\(message.content.count)")
                    infoRow(pluginLocalization.string("Line Count"), value: "\(lineCount(in: message.content))")
                    infoRow(
                        pluginLocalization.string("Content is empty"),
                        value: pluginLocalization.string(
                            message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Yes" : "No"
                        )
                    )
                    if let thinking = message.metadata["thinkingContent"], !thinking.isEmpty {
                        infoRow(
                            pluginLocalization.string("Thinking Content"),
                            value: String(format: pluginLocalization.string("%lld characters"), thinking.count)
                        )
                    }
                    if message.metadata["hasImages"] == "true" {
                        infoRow(pluginLocalization.string("Image Attachment"), value: pluginLocalization.string("Yes"))
                    }
                }

                if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                    infoSection(
                        String(format: pluginLocalization.string("Tool Calls (%lld)"), toolCalls.count)
                    ) {
                        ForEach(Array(toolCalls.enumerated()), id: \.offset) { index, toolCall in
                            toolCallSummary(index: index + 1, toolCall: toolCall)
                        }
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 320)
        .frame(maxHeight: 460)
    }

    @ViewBuilder
    private func infoSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(theme.textSecondary)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: 2) {
                content()
            }
        }
    }

    private func infoRow(_ label: String, value: String, isMono: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.textSecondary)
                .frame(width: 88, alignment: .leading)

            Text(value)
                .font(.system(size: 11, design: isMono ? .monospaced : .default))
                .foregroundColor(theme.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private func infoMultilineRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.textSecondary)

            ScrollView(.vertical, showsIndicators: true) {
                Text(value)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(theme.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 120)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func toolCallSummary(index: Int, toolCall: MessageToolCall) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            infoRow(
                String(format: pluginLocalization.string("Tool action %lld"), index),
                value: toolCall.displayDescription ?? pluginLocalization.string("Run tool")
            )
            infoRow("ID", value: toolCall.id, isMono: true)
            infoRow(
                pluginLocalization.string("Arguments"),
                value: String(format: pluginLocalization.string("%lld characters"), toolCall.arguments.count)
            )
            infoRow(pluginLocalization.string("Result"), value: toolCallResultSummary(toolCall))
        }
        .padding(.vertical, 4)
    }

    private func toolCallResultSummary(_ toolCall: MessageToolCall) -> String {
        guard let result = toolCall.result else {
            return pluginLocalization.string("Waiting")
        }

        var parts = [pluginLocalization.string(result.isError ? "Failed" : "Succeeded")]
        parts.append(
            String(format: pluginLocalization.string("%lld characters"), result.content.count)
        )
        if let duration = result.duration {
            parts.append(MessageViewHelpers.formatDuration(duration))
        }
        return parts.joined(separator: " · ")
    }

    private func errorDetailSummary(for message: Message) -> String? {
        ErrorTransportDetailsResolver.infoPopoverErrorSummary(for: message)
    }

    @ViewBuilder
    private func httpDetailRows() -> some View {
        if let status = message.httpStatusCode {
            infoRow(pluginLocalization.string("HTTP Status Code"), value: "\(status)", isMono: true)
        }
        if let body = message.httpBody, !body.isEmpty {
            infoMultilineRow(pluginLocalization.string("HTTP Response Body"), value: body)
        }
    }

    private func displayValue(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "—"
        }
        return value
    }

    private func lineCount(in text: String) -> Int {
        max(1, text.components(separatedBy: .newlines).count)
    }
}
