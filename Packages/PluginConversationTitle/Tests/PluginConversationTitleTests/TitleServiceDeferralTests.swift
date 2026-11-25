import Foundation
import KernelCore
import ProviderAgentLoop
import ProviderConversation
import ProviderLifecycleHooks
import ProviderMessage
import Testing

@testable import PluginConversationTitle

/// `TitleService` 的回合空闲等待测试：助手回复优先于自动标题。
///
/// 对应 LUMI-HANDOFF.md「Resume and verify」第 1 条中的「Defer title generation
/// until the assistant turn finishes or local inference is idle」：
/// 首条用户消息落库时若该会话的 agent 回合仍在运行，标题 LLM 请求必须推迟；
/// 回合空闲后放行。观察到的停滞（标题请求完成而主回合永卡 `.requestingLLM`）
/// 正是标题与主回合同时竞争共享 MLX 推理所致。
@Suite("自动标题回合等待")
@MainActor
struct TitleServiceDeferralTests {

    // MARK: - Doubles

    /// 最小 agent loop 桩：只驱动 `isRunning` 分支，其余成员不可达。
    private final class StubAgentLoop: AgentLoopProviding {
        var running = false

        func addAgentLoopObserver(
            _ callback: @escaping (AgentLoopEvent) -> Void
        ) -> any AgentLoopObserverHandle {
            StubAgentLoopObserverHandle()
        }
        func runTurn(in conversationID: UUID) async throws -> AgentLoopOutcome {
            fatalError("测试桩不应触发 runTurn")
        }
        func resumeTurn(in conversationID: UUID, request: AgentTurnResumeRequest) async throws -> AgentLoopOutcome {
            fatalError("测试桩不应触发 resumeTurn")
        }
        func cancelTurn(in conversationID: UUID) {}
        func state(for conversationID: UUID) -> AgentLoopState {
            running ? .running : .idle
        }
        func suspension(for conversationID: UUID) -> AgentLoopSuspension? { nil }
        func isRunning(for conversationID: UUID) -> Bool { running }
        func currentTurnID(for conversationID: UUID) -> UUID? { nil }
        func setLifecycleHooks(_ hooks: (any ProviderLifecycleHooks.LifecycleHooksProviding)?) {}
    }

    private final class StubAgentLoopObserverHandle: AgentLoopObserverHandle {
        func cancel() {}
    }

    // MARK: - Helpers

    /// 把桩 agent loop 注册进 kernel 再构造服务；与生产 onBoot 的装配一致。
    private func makeService(
        agentLoop: StubAgentLoop?,
        timing: TitleDeferralTiming
    ) -> (TitleService, TitleTestDoubles.StubMessageManager, TitleTestDoubles.StubConversationManager, TitleTestDoubles.StubLLMManager, UUID) {
        let kernel = KernelCoreContainer()
        if let agentLoop {
            // swiftlint:disable:next force_try
            try! kernel.registerProvider((any AgentLoopProviding).self, agentLoop)
        }
        let conversationID = UUID()
        let conversations = TitleTestDoubles.StubConversationManager()
        conversations.appendSummary(id: conversationID, title: nil)
        let messages = TitleTestDoubles.StubMessageManager()
        let llm = TitleTestDoubles.StubLLMManager(responseContent: "标题")
        let service = TitleService(
            kernel: kernel,
            conversations: conversations,
            messages: messages,
            llmProvider: llm,
            deferTiming: timing
        )
        return (service, messages, conversations, llm, conversationID)
    }

    private func userMessage(_ content: String, in conversationID: UUID) -> Message {
        Message(conversationID: conversationID, role: .user, content: content)
    }

    /// 轮询直到条件成立或超时；轮询间隔让出 MainActor，供等待中的 Task 推进。
    private func awaitEventually(maxMilliseconds: Int = 3_000, _ condition: () -> Bool) async -> Bool {
        let deadline = ContinuousClock.now + .milliseconds(maxMilliseconds)
        while !(condition() || ContinuousClock.now >= deadline) {
            try? await Task.sleep(for: .milliseconds(10))
        }
        return condition()
    }

    // MARK: - Tests

    /// 回合运行期间标题请求必须被推迟；回合空闲后放行。
    @Test("回合运行期间推迟标题请求，回合空闲后放行")
    func defersTitleWhileTurnIsRunning() async {
        let agentLoop = StubAgentLoop()
        agentLoop.running = true
        let (service, messages, conversations, llm, conversationID) = makeService(
            agentLoop: agentLoop,
            timing: .immediate
        )
        defer { service.stop() }

        messages.emitInserted(userMessage("回合运行中的首条消息", in: conversationID))

        // 立即放行的话标题请求此刻已经发出；推迟语义下它还没有。
        #expect(llm.receivedRequests.isEmpty, "回合运行期间不应发起标题 LLM 请求")

        agentLoop.running = false
        let landed = await awaitEventually {
            llm.receivedRequests.count == 1 && conversations.title(of: conversationID) == "标题"
        }
        #expect(landed, "回合空闲后应放行标题请求并落库")
    }

    /// 回合空闲时标题立即生成，等待逻辑不得引入额外拦截。
    @Test("回合空闲时立即生成标题")
    func generatesTitleWhenTurnIsIdle() async {
        let agentLoop = StubAgentLoop()
        agentLoop.running = false
        let (service, messages, conversations, llm, conversationID) = makeService(
            agentLoop: agentLoop,
            timing: .immediate
        )
        defer { service.stop() }

        messages.emitInserted(userMessage("空闲会话的首条消息", in: conversationID))
        let landed = await awaitEventually {
            llm.receivedRequests.count == 1 && conversations.title(of: conversationID) == "标题"
        }
        #expect(landed)
    }

    /// 回合悬挂不退出时，标题等待超时后放行：单个长回合不能把标题永久堵死。
    ///
    /// 超时只是放行 —— 后续护栏（复核 + 兜底标题）决定最终是否写库。
    @Test("回合长期运行时等待超时并放行")
    func timesOutWhenTurnNeverEnds() async {
        let agentLoop = StubAgentLoop()
        agentLoop.running = true
        let timing = TitleDeferralTiming(
            assistantTurnStartGrace: .zero,
            agentTurnIdlePollInterval: .milliseconds(5),
            agentTurnIdleWaitTimeout: .milliseconds(100)
        )
        let (service, messages, conversations, llm, conversationID) = makeService(
            agentLoop: agentLoop,
            timing: timing
        )
        defer { service.stop() }

        messages.emitInserted(userMessage("永不结束的回合", in: conversationID))

        let landed = await awaitEventually(maxMilliseconds: 3_000) {
            llm.receivedRequests.count == 1 && conversations.title(of: conversationID) == "标题"
        }
        #expect(landed, "等待超时后标题请求应照常发出")
    }

    /// agent loop 未注册（测试 / headless / 插件未启用）时保持原行为：
    /// 不等待、直接生成。
    @Test("agent loop 未注册时不等待")
    func skipsDeferralWithoutAgentLoop() async {
        let (service, messages, conversations, llm, conversationID) = makeService(
            agentLoop: nil,
            timing: .immediate
        )
        defer { service.stop() }

        messages.emitInserted(userMessage("没有回合管理器的消息", in: conversationID))
        let landed = await awaitEventually {
            llm.receivedRequests.count == 1 && conversations.title(of: conversationID) == "标题"
        }
        #expect(landed)
    }
}
