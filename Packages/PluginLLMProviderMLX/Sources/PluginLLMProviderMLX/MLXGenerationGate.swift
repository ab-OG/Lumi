import Foundation

/// MLX 生成门闩：同一时刻只允许一个请求进入模型准备与流式生成。
///
/// `TitleService` 与 agent loop 共用同一个 `MLXRuntime`；并发的 prepare/generate
/// 曾被怀疑造成「标题请求完成而主回合永卡 `.requestingLLM`」的停滞（见
/// `LUMI-HANDOFF.md`）。每个进入 `generate` 的请求先 `acquire`；生成结束、
/// 抛错或取消路径完成后必须 `release`，下一个排队请求随即获得槽位。
///
/// 排队按 FIFO 唤醒。助手回复的优先级不在这里实现：`TitleService` 自己把标题
/// 请求推迟到回合空闲之后（见 `TitleService.deferTitleUntilAssistantTurnIdle`），
/// 门闩只负责保证不并发。
@MainActor
final class MLXGenerationGate {
    private(set) var isGenerating = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    /// 获取生成槽位；已被占用时挂起排队。
    ///
    /// 等待期间任务若被取消，取消信号不会中断挂起本身（continuation 语义），
    /// 由调用方在获得槽位后用 `Task.checkCancellation` 尽快让出。
    func acquire() async {
        if !isGenerating {
            isGenerating = true
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    /// 释放生成槽位并唤醒下一个排队请求；无排队时关闭占用标志。
    ///
    /// 必须与 ``acquire`` 一一配对（成功路径与失败/取消路径各一次），否则
    /// 门闩会永久卡死或放行并发请求。
    func release() {
        if !waiters.isEmpty {
            waiters.removeFirst().resume()
        } else {
            isGenerating = false
        }
    }
}
