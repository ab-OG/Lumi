import Foundation
import Testing

@testable import PluginLLMProviderMLX

/// `MLXGenerationGate` 的串行化语义测试。
///
/// 这批用例对应 LUMI-HANDOFF.md「Resume and verify」第 1 条中的串行化要求：
/// 同一时刻只允许一个请求进入生成；槽位在 release 后交给下一个排队请求
/// （FIFO）。助手回复对标题的优先级不在门闩本身实现（见 TitleService 的
/// 回合空闲等待），这里锁定的是门闩不并发这一底线。
@Suite("MLX 生成门闩")
@MainActor
struct MLXGenerationGateTests {

    /// 跨任务记录「进入槽位」事件的哨兵；门闩与测试都在 MainActor 上，
    /// 但探测标志的读写发生在不同 Task 里，加锁只是顺手保干净。
    private final class Probe: @unchecked Sendable {
        private let lock = NSLock()
        private var entered = false
        func mark() {
            lock.lock()
            entered = true
            lock.unlock()
        }
        var hasEntered: Bool {
            lock.lock()
            defer { lock.unlock() }
            return entered
        }
    }

    /// 让出执行权，给挂起/唤醒的任务一个调度机会。
    private func settle(steps: Int = 10) async {
        for _ in 0..<steps { await Task.yield() }
    }

    /// 第一个 acquire 立即持锁；第二个 acquire 在 release 前保持挂起，
    /// release 后按 FIFO 接过槽位。
    @Test("已占用时排队，release 后放行")
    func secondAcquireWaitsUntilRelease() async {
        let gate = MLXGenerationGate()
        await gate.acquire()
        #expect(gate.isGenerating)

        let probe = Probe()
        let waiter = Task {
            await gate.acquire()
            probe.mark()
        }
        await settle()
        #expect(!probe.hasEntered, "未 release 前等待者不得进入")

        gate.release()
        await waiter.value
        #expect(probe.hasEntered, "release 后等待者应获得槽位")

        // 等待者接过槽位后，无排队时 release 应关闭占用标志。
        gate.release()
        #expect(!gate.isGenerating)
    }

    /// 多个排队请求按 FIFO 唤醒；每个持有者自己 release 才轮到下一个。
    @Test("多个等待者按 FIFO 逐个放行")
    func releasesWaitersOneAtATimeInFIFO() async {
        let gate = MLXGenerationGate()
        await gate.acquire()

        var order: [Int] = []
        let waiters = (1...3).map { index in
            Task {
                await gate.acquire()
                order.append(index)
                try? await Task.sleep(for: .milliseconds(5))
                gate.release()
            }
        }
        // 交出初始持有；此后任务 1..3 形成自链：下一个 acquire 由上一个 release 放行。
        gate.release()
        for waiter in waiters {
            await waiter.value
        }

        // 每个持有者自己 release 才轮到下一个，因此完成顺序就是排队顺序。
        #expect(order == [1, 2, 3])
        #expect(!gate.isGenerating)
    }

    /// 排队期间被取消的请求不应把门闩占死：release 唤醒的是队首，
    /// 队列最终能清空。
    @Test("取消的等待者不阻塞后续请求")
    func cancelledWaiterDoesNotDeadlockGate() async {
        let gate = MLXGenerationGate()
        await gate.acquire()

        let cancelledWaiter = Task {
            await gate.acquire()
        }
        await settle()
        cancelledWaiter.cancel()
        gate.release()

        // 第一个 release 唤醒被取消的等待者（它拿到槽位后立即让出语义由
        // 调用方的 checkCancellation 负责）；下一次 release 交给后续请求。
        let lateWaiter = Task {
            await gate.acquire()
            gate.release()
        }
        await settle()
        gate.release()
        await lateWaiter.value
        #expect(!gate.isGenerating)
    }
}
