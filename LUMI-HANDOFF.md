# Lumi development handoff

## Saved work

- Draft PR #2 contains the local tokenizer fix and the Metal command-encoder lifetime fix. The tokenizer loads from the local model folder with `AutoTokenizer.from(modelFolder:)`.
- This branch preserves the subsequent SwiftPM lockfile update. The local Xcode build also selected an Apple development team. Select your own team in Xcode if a signed build needs one.
- The `personal/english-settings` branch contains the plugin manager English localization work and its string catalog. Integration and visual verification remain pending.

## Observed behavior

- A debug MLX run with Qwen returned the expected answer to the arithmetic prompt. The production build and DeepSeek inference were not verified.
- Qwen3-4B-Instruct-2507-4bit and Qwen3-1.7B-4bit model files were present and checked locally. The production store also held Qwen3-4B-Instruct-2507-4bit.
- On an Apple M4 MacBook Air with 16 GB RAM, three recorded samples had time to first token near 50 to 52 seconds. Other successful debug samples showed roughly 40 to 50 tokens per second after generation began.
- A later Debug run showed the title request complete while the assistant turn stayed in `.requestingLLM`. The UI kept the send state active and queued more sends. `TitleService` and the agent loop both invoked the shared MLX runtime. Their overlapping preparation and generation are a suspected contributor to the stall. Measure cold startup separately from contention when resuming.
- The final Antigravity implementation attempt was interrupted. Its handoff records no code changes from that attempt. The diagnostics and next steps below remain the latest recorded state.

## Resume and verify

1. Give the assistant reply priority over automatic titles. Serialize MLX preparation and streaming for the duration of each request. Release the next request after generation ends or cancellation finishes. Defer title generation until the assistant turn finishes or local inference is idle.
2. Use a synthetic file with three facts to verify offline file summary and a follow-up grounded in that file. Bound the test duration and record time to first visible reply, correctness, and whether the next send works after cancellation.
3. Integrate the English branch and check the plugin manager in the running app.
4. Verify a release candidate with its own bundle identifier and storage directory before testing against production. Repeat the inference checks in that build and record which models pass.
