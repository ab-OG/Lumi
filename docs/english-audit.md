# English interface audit — baseline (November 25, 2026)

Milestone 1 (PERSONAL.md): a complete English interface and a verified local-model
conversation on an M4 MacBook Air (16 GB RAM). This document is the tracking
artifact for the English part. It records the audit method, the measured
inventory, and the PR slicing plan. It is a baseline: counts move as slices land.

## Status

| Piece | Status |
|---|---|
| Plugin Manager screen → English source + zh translations | PR #4 (draft) |
| MLX TitleService/agent-loop contention fix | PR #3 (draft, retargeted to main; merge after on-Mac verification) |
| Tokenizer + Metal fixes | merged (PR #2) |
| Project docs | merged (PR #1) |
| Settings/General English | merged (PR #6) |
| Settings catalogs en+zh sync, singular/plural count labels, key audits | merged (PR #5) |
| Provider settings/pickers English | draft PR (`personal/english-provider-pickers`): Aliyun/CommandCode/OpenCode/StepFun/Tencent/Zhipu/MiniMax identity strings, ModelSelector catalog en values, LumiLocalizationKit locale-precedence fix, new `Scripts/check-localization-keys.py` gate |
| Tools & permission prompts English | draft PR (`personal/english-tools-permissions`, stacked on the provider-pickers PR): KitAgentTool risk/authorization labels, PluginToolManager tool descriptions + risk reasons + job messages, PluginMessageRenderer permission-card text |
| Errors & agent-loop UI English | draft PR (`personal/english-agentloop-ui`, stacked on the tools-and-permissions PR): PluginMessageListDetailed send-state strings, PluginMessageRenderer turn-complete divider, PluginAgentLoop LLM recovery hint (LLM-facing), LumiApp bootstrap-failure screen + low-disk toast + Settings window title |
| PMR catalog migration (39 gate findings) | draft PR (`personal/english-pmr-catalog`, stacked on the agent-loop PR): all 39 findings fixed — 18 zh-source keys renamed to English source keys, 9 previously hard-coded strings routed through `pluginLocalization`, tool-call state words, step-group summaries, Goal-continuation labels, plugin title/description, Collapse/Expand keys added; gate now clean |
| PMR info popover + diagnostic strip English (MessageInfoButton, MessageDiagnosticStrip) | draft PR (`personal/english-pmr-info-diagnostic`, stacked on the pmr-catalog PR): 42 keyed MessageInfoButton calls + diagnostic strip labels |
| Computer-use authorization card English | draft PR (`personal/english-computer-use-auth-card`, stacked on the pmr-info PR): blocked Computer Use guidance localized, `ComputerUseLocalizationIntegrityTests` added |
| Plugin long tail — Mail UI English | draft PR (`personal/english-mail`, stacked on the computer-use-auth-card PR): all 24 PluginMail gate findings fixed — 23 zh-source keys renamed to English source keys with en+zh-Hans/zh-Hant/zh-HK/zh-TW values (the `邮件` key merged into the existing fully-localized `Mail` key), plus ~50 previously hard-coded UI strings (settings, account form, compose, list, reader, workspace, provider presets, workspace error banners) routed through `pluginLocalization`; attachments count label uses singular/plural keys (`%lld attachment`/`%lld attachments`); new `MailCatalogMigrationIntegrityTests` (en≡key, 5 locales, legacy zh keys removed, placeholder parity, count pair). Verified: swift test PluginMail all pass, gate OK, tool-failure-strings OK, full unsigned app build (scheme Lumi, Debug) BUILD SUCCEEDED. MailAgentTools.swift LLM-facing strings deliberately left for the agent-tool long-tail slice |
| Conversation list UI English (PluginConversationList) | draft PR (`personal/english-conversation-list`, stacked on the mail PR): all 5 gate findings fixed — 4 zh-source keys renamed to English keys with en+zh-Hans/zh-Hant/zh-HK/zh-TW values (`删除` merged into the existing fully-localized `Delete` key), plus hard-coded header titles, scope tabs, row placeholder, relative timestamps (`Date.relativeTime`, which now matches its documented English formats), count badge (singular/plural), and accessibility labels routed through `pluginLocalization`; new `ConversationListCatalogMigrationIntegrityTests`; Verified: swift test PluginConversationList 68 tests pass, gate OK, tool-failure-strings OK, full unsigned app build (scheme Lumi, Debug) BUILD SUCCEEDED. locale-dependent test pins updated to resolve via `pluginLocalization`. `GetRecentConversationsTool` LLM-facing text left for the agent-tool long-tail slice |
| PluginDatabaseManager catalog completion | draft PR (`personal/english-database-manager`, stacked on the conversation-list PR): all 27 gate findings fixed — 25 English keys filled with en ≡ key values (zh translations untouched), `Index Type` en value corrected from 'Type' to the key, and the DEBUG-preview-referenced `No tables` key added with full locales (no source changes needed; all 27 keys already route through `pluginLocalization`) | Verified: swift test PluginDatabaseManager 76 tests pass (incl. 3 new integrity tests), gate OK, tool-failure-strings OK, full unsigned app build (scheme Lumi, Debug) BUILD SUCCEEDED.
| Plugin long tail (Browser, EditorService, TextActions, BrewManager, QuickFileSearch, …) | not started |
| On-device English UI + local-model conversation verification | **requires Ankit's Mac** |

## Established translation pattern

Upstream already ships the machinery; new work follows PR #4:

- Per package `Support/PluginLocalization.swift` exposing `pluginLocalization`.
- Visible strings become English source keys: `pluginLocalization.string("English text")`.
- All previous Chinese strings move into `Resources/Localizable.xcstrings` as
  `zh-Hans` (+ zh-Hant/zh-HK/zh-TW where the catalog already has them).
- Catalogs keep `sourceLanguage: en`; localization support is preserved, not removed.
- Count labels use the singular/plural helper (`pluginLocalization.count`) so
  count 1 reads singular (“1 local provider”) and other counts read plural.
- Every visible-key migration must pass `Scripts/check-localization-keys.py <pkgs>`:
  every source key exists in its catalog with an explicit en value (en ≡ key, with
  a temporary allowlist for MiniMax legacy keys) plus zh-Hans, and no Chinese keys.
- Fixed in the provider-pickers PR: `LumiLocalization` now resolves the
  explicitly passed locale **before** system `preferredLanguages`; previously an
  `en` entry in a catalog shadowed `locale: zh-Hans` lookups on English systems.

Caution learned in PR #4: keys that differ only by trailing punctuation
generate colliding string symbols (`GenerateStringSymbols` fails the build).
Unify or distinctly name such keys.

## Code-level Chinese string literals (best-effort scan of non-comment lines)

| Package / module | literal hits |
|---|---|
| Vendor | 342 |
| EditorService | 210 |
| PluginMail | 130 → Mail UI done in the mail PR: all Views/Services user-visible strings now English source keys; remaining hits are comments, Logger lines, and `Agent/MailAgentTools.swift` LLM-facing tool text (separate follow-up) |
| PluginMessageRenderer | 117 → permission-card strings done in the tools PR (question, Allow/Deny/Always-allow labels, fallback note); remaining 145 raw lines are the long-tail slice (loggers, comments, remaining UI rows) |
| ProjectRAGEngine | 71 |
| KitCADDesigner | 69 |
| PluginSettingGeneral | 64 → 18 non-comment (PR #6: all visible strings now `pluginLocalization.string("<English>")` with singular/plural pairs for count labels; remaining 18 are Logger lines, `run(label:)` log labels, and one verbose-only PATH hint) |
| PluginLLMProviderSettings | 61 → 0 non-comment (PR #6: keys migrated zh → en source, count labels singular/plural, nested-ternary call sites unwrapped, plugin metadata name localized; Chinese preserved as zh-Hans) |
| PluginDatabaseManager | 56 |
| PluginNetworkManager | 55 |
| ScreenRecorderPlugin | 55 |
| PluginClipboardManager | 53 |
| PluginBrewManager | 48 |
| PluginGit | 47 |
| FinderSync+Actions.swift | 43 |
| PluginAppManager | 43 |
| PluginLLMContext | 42 |
| PluginAppIconDesigner | 42 |
| PluginConversationManager | 42 |
| PluginOcr | 39 |
| PluginAgentLoop | 37 |
| PluginToolManager | 36 → 0 visible non-comment (tools PR: tool displayDescription, ShellCommandRiskAnalyzer reasons, ToolExecutionManager job messages; ToolManager/ViewModel/Views UI was already English; remaining hits are comments and logger lines) |
| FinderSync.swift | 34 |
| PluginDiskManager | 34 |
| PluginBrowser | 34 |
| PluginPrototypeDesigner | 33 |
| PluginDockerManager | 32 |
| PluginProjectFileTree | 32 |
| PluginCaffeinate | 30 |
| PluginAppStoreConnect | 29 |
| PluginMindMapDesigner | 28 |
| PluginVideoConverter | 27 |
| PluginAppStorePromoDesigner | 25 |
| PluginHostsManager | 24 |
| PluginGoalTask | 24 |
| PluginStoryWriter | 23 |
| PluginTerminal | 23 |
| PluginCADDesigner | 23 |
| PluginLLMProviderMiniMax | 23 → 0 visible non-comment (provider-pickers PR: provider identity/picker strings migrated to English source keys, zh preserved; remaining hits are `#if DEBUG` #Preview fixtures and Logger-only fallbacks) |
| PluginLLMProviderAliyun | → 0 visible non-comment (provider-pickers PR: identity strings migrated; per-package catalog added with en + zh) |
| PluginLLMProviderCommandCode | → 0 visible non-comment (provider-pickers PR, same pattern) |
| PluginLLMProviderOpenCode | → 0 visible non-comment (provider-pickers PR, same pattern) |
| PluginLLMProviderStepFun | → 0 visible non-comment (provider-pickers PR, same pattern) |
| PluginLLMProviderTencent | → 0 visible non-comment (provider-pickers PR, same pattern) |
| PluginLLMProviderZhipu | → 0 visible non-comment (provider-pickers PR, same pattern) |
| PluginMessageListZCode | 21 |
| … 102 more modules | 616 |
| **Total** | **2817** |

## Catalogs missing `en` for some keys

| Catalog | keys missing en | total keys |
|---|---|---|
| Packages/PluginAppStoreConnect/Resources/Localizable.xcstrings | 279 | 286 |
| Packages/PluginACP/Resources/Localizable.xcstrings | 34 | 95 |
| Packages/PluginDatabaseManager/Resources/Localizable.xcstrings | 0 | 157 |
| Packages/PluginMail/Resources/Localizable.xcstrings | 0 | 80 |
| Packages/PluginSettingGeneral/Resources/Localizable.xcstrings | 3 | 77 |
| Packages/PluginAppStorePromoDesigner/Resources/Localizable.xcstrings | 22 | 76 |
| Packages/PluginSystemBenchmark/Resources/Localizable.xcstrings | 14 | 49 |
| Packages/PluginTextActions/Resources/Localizable.xcstrings | 12 | 53 |
| Packages/PluginMessageRenderer/Resources/Localizable.xcstrings | 10 | 66 |
| Vendor/LumiUI/Resources/Localizable.xcstrings | 9 | 108 |
| Packages/PluginModelSelector/Resources/Localizable.xcstrings | 0 | 30 |
| Packages/PluginLLMProviderSettings/Resources/Localizable.xcstrings | 0 | 66 |
| Packages/PluginConversationList/Resources/Localizable.xcstrings | 0 | 37 |
| Vendor/LumiPluginBookletMaker/Resources/Localizable.xcstrings | 8 | 337 |
| Packages/PluginWhiteNoise/Resources/Localizable.xcstrings | 6 | 35 |
| Packages/PluginMCP/Resources/Localizable.xcstrings | 6 | 56 |
| Packages/PluginResumeDesigner/Resources/Localizable.xcstrings | 5 | 62 |
| Packages/PluginMindMapDesigner/Resources/Localizable.xcstrings | 5 | 99 |
| Packages/PluginAgentRules/Resources/Localizable.xcstrings | 4 | 22 |
| Packages/PluginGitChatToolbar/Resources/Localizable.xcstrings | 4 | 15 |
| Packages/PluginChatScreenshot/Resources/Localizable.xcstrings | 4 | 7 |
| Packages/KitMarkdown/Resources/Localizable.xcstrings | 3 | 7 |
| Packages/PluginActivityHeatmap/Resources/Localizable.xcstrings | 3 | 40 |
| Packages/PluginGit/Resources/Localizable.xcstrings | 3 | 64 |
| Packages/PluginAppManager/Resources/Localizable.xcstrings | 3 | 61 |
| Packages/PluginDiskManager/Resources/Localizable.xcstrings | 3 | 154 |
| Packages/PluginNetworkManager/Resources/Localizable.xcstrings | 3 | 87 |
| Packages/PluginHostsManager/Resources/Localizable.xcstrings | 3 | 26 |
| Packages/PluginAppIconDesigner/Resources/Localizable.xcstrings | 3 | 86 |
| Packages/PluginSkill/Resources/Localizable.xcstrings | 3 | 20 |
| Packages/PluginClipboardManager/Resources/Localizable.xcstrings | 2 | 47 |
| Packages/PluginDisplayControl/Resources/Localizable.xcstrings | 2 | 33 |
| Packages/PluginDevice/Resources/Localizable.xcstrings | 2 | 114 |
| Packages/PluginDockerManager/Resources/Localizable.xcstrings | 2 | 44 |
| Packages/PluginNetto/Resources/Localizable.xcstrings | 2 | 49 |
| Packages/PluginPortManager/Resources/Localizable.xcstrings | 2 | 36 |
| Packages/PluginToolActivity/Resources/Localizable.xcstrings | 2 | 15 |
| Packages/PluginGitWorkspace/Resources/Localizable.xcstrings | 1 | 20 |
| Packages/PluginMessageListDetailed/Resources/Localizable.xcstrings | 1 | 8 |
| Packages/PluginMessageListBrief/Resources/Localizable.xcstrings | 1 | 19 |
| Packages/PluginFinder/Resources/Localizable.xcstrings | 1 | 6 |
| Packages/PluginAskUser/Resources/Localizable.xcstrings | 1 | 2 |
| Packages/PluginTerminal/Resources/Localizable.xcstrings | 1 | 5 |
| Packages/PluginRClick/Resources/Localizable.xcstrings | 1 | 76 |
| Packages/PluginRegistryManager/Resources/Localizable.xcstrings | 1 | 46 |
| Packages/PluginMessageListZCode/Resources/Localizable.xcstrings | 1 | 8 |
| Packages/PluginComputerUse/Resources/Localizable.xcstrings | 1 | 52 |
| Packages/KitCADDesigner/Resources/Localizable.xcstrings | 1 | 116 |
| Packages/PluginBrewManager/Resources/Localizable.xcstrings | 1 | 55 |
| Packages/PluginQuickFileSearch/Resources/Localizable.xcstrings | 1 | 17 |
| Packages/PluginMessageListEmpty/Resources/Localizable.xcstrings | 1 | 22 |
| Packages/PluginGoalTask/Resources/Localizable.xcstrings | 1 | 15 |
| Packages/PluginLLMManager/Resources/Localizable.xcstrings | 1 | 12 |
| Packages/PluginConversationSpeed/Resources/Localizable.xcstrings | 1 | 26 |
| Packages/PluginProjectFileTree/Resources/Localizable.xcstrings | 1 | 39 |
| Packages/PluginDiskSpeedTest/Resources/Localizable.xcstrings | 1 | 11 |
| Packages/PluginMessageListStandard/Resources/Localizable.xcstrings | 1 | 8 |
| Vendor/LumiPluginPluginManager/Resources/Localizable.xcstrings | 1 | 4 |

## PR slicing plan (focused, reviewable, each lands as a draft PR against main)

1. **PR #4 — Plugin Manager** (Vendor/LumiPluginPluginManager). Done as draft.
2. **Settings core**: PluginSettingGeneral (64 hits), PluginLLMProviderSettings (61),
   ToolManager settings surfaces. Done and merged (PR #6). Three stale
   empty-localization keys remain in the PluginSettingGeneral catalog
   (`%lld`, `Bundle ID`, `Check whether a newer version of Lumi is available.`) —
   dead keys to sweep in a later cleanup.
3. **Providers**: provider metadata visible in pickers (names, descriptions),
   ModelSelector, and MLX provider plugin strings ("MLX 本地供应商" etc.).
   Provider identity strings for Aliyun/CommandCode/OpenCode/StepFun/Tencent/
   Zhipu/MiniMax plus the ModelSelector catalog are done in the
   provider-pickers PR; remaining: MLX provider plugin strings and any provider
   text living under Vendor.
4. **Tools & permission prompts**: tool schema descriptions rendered in prompts,
   PluginToolManager manager UI + permission dialogs (this text also reaches
   the LLM; keep changes semantics-preserving).
   Done in the tools PR: KitAgentTool CommandRiskLevel/ToolCallAuthorizationState
   labels + reasons, PluginToolManager tool descriptions/risk reasons/job
   messages, PluginMessageRenderer permission-card question + buttons.
   Tool schema descriptions were already English upstream.
   Remaining in this area: PluginComputerUse authorization card, and the PMR
   info popover / diagnostic strip strings (MessageInfoButton,
   MessageDiagnosticStrip) — the rest of PMR's catalog debt is fixed in the
   pmr-catalog PR.
5. **Errors & agent-loop UI**: done in the agentloop-ui PR:
   - PluginMessageListDetailed: the 4 status strings (`status.sending` etc.) had
     Chinese as their en catalog value; migrated to English source keys
     ("Sending message…", "Thinking…", "Executing tool…", "Waiting for your
     input…") plus a new "Executing %@…" format key for the status + job
     description compound that mixed Chinese scaffolding with English tool
     names after the tools PR ("正在Read a.txt…"). zh-Hans/Hant/HK/TW values
     preserved. Fixed matching test pins in ListV3ViewModelTests.
   - PluginMessageRenderer: `TurnCompletedMessageView` divider title "结束" and
     detail " · 耗时 X" → English source keys "Turn complete", "Duration %@"
     with zh translations preserved in the PMR catalog.
   - PluginAgentLoop: `llmRecoveryHint` system-prompt recovery instruction is
     now English (it is sent to the LLM as a temporary system message, not UI;
     switched for consistency with the English-model-facing prompts).
   - LumiApp (host target, no xcstrings of its own): bootstrap-failure screen
     (titles, explanations, phase words, action buttons, technical-details
     labels), the low-disk toast, and the Settings window title now follow the
     existing `LumiMenuBarController` `localized(_:chinese:)` pattern
     (`lumiAppString(_:chinese:)`, English-first with zh fallback).
   Catalog-integrity tests require all 5 locales (en, zh-Hans, zh-Hant,
   zh-HK, zh-TW) on every touched key. Verified: swift test
   PluginMessageListDetailed (120) / PluginMessageRenderer (213) /
   PluginAgentLoop (116) all pass; check-localization-keys.py OK for
   Detailed + AgentLoop (PMR still has its 39 pre-existing long-tail problems,
   unchanged by this PR); check-tool-failure-strings.py passes; full app builds
   with unsigned `xcodebuild` (scheme Lumi, Debug).
   Remaining in this area: fixed by the pmr-catalog PR for the 39 gate findings
   (PMR gate now clean); still open: PMR info popover (MessageInfoButton) +
   diagnostic strip strings, PluginComputerUse authorization card,
   agent-loop event titles in PluginLLMProviderMLX
   ("生成中"/"结束" in MLXRuntime.swift are currently never consumed
   downstream — dead strings, noted for later cleanup).
6. **Plugin long tail** (several PRs, roughly by visibility):
   Browser/DiskManager/ClipboardManager/AppManager → Mail (done in the mail PR:
   all 24 gate findings + hard-coded UI strings migrated; MailAgentTools
   LLM-facing text and the agent-tool long tail remain) /MessageRenderer →
   EditorService & Kits → designers/recorder utilities.
7. **Vendor long tail** (LumiProviders, LumiUI, plugin vendor packages).

Each PR: only its package(s), updated catalog with en + zh entries, a build of
the touched package(s), the tool-failure-strings gate, and an explicit list of
remaining modules. Nothing is claimed "complete English" until the whole audit
table above is green plus the on-device checks.

## Verification requiring Ankit's Mac (cannot be done in this environment)

- Xcode 27 dev build with a development bundle identifier and isolated storage
  (dev app must not touch the installed Lumi's data; debug storage root
  `db_debug_v6` ≠ production `db_production_v6` needs visual confirmation).
- English UI walkthrough: Settings, plugin management, providers, permission
  prompts, errors.
- Local-model conversation (record exact model, e.g. Qwen3-4B-Instruct-2507-4bit)
  and a small file task in a test folder; record time-to-first-reply and result.
- Verification of PR #3's contention fix under real inference.

## License / attribution

GPLv3 LICENSE and upstream README are preserved; upstream remote remains
CofficLab/Lumi. No upstream files besides those being localized are modified.
