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
| Settings/General English | **PluginSettingGeneral + PluginLLMProviderSettings → PR #6 (draft)** |
| Provider settings/pickers English | not started |
| Tools & permission prompts English | not started |
| Errors & agent-loop UI English | not started |
| Plugin long tail (Mail, EditorService, MessageRenderer, …) | not started |
| On-device English UI + local-model conversation verification | **requires Ankit's Mac** |

## Established translation pattern

Upstream already ships the machinery; new work follows PR #4:

- Per package `Support/PluginLocalization.swift` exposing `pluginLocalization`.
- Visible strings become English source keys: `pluginLocalization.string("English text")`.
- All previous Chinese strings move into `Resources/Localizable.xcstrings` as
  `zh-Hans` (+ zh-Hant/zh-HK/zh-TW where the catalog already has them).
- Catalogs keep `sourceLanguage: en`; localization support is preserved, not removed.

Caution learned in PR #4: keys that differ only by trailing punctuation
generate colliding string symbols (`GenerateStringSymbols` fails the build).
Unify or distinctly name such keys.

## Code-level Chinese string literals (best-effort scan of non-comment lines)

| Package / module | literal hits |
|---|---|
| Vendor | 342 |
| EditorService | 210 |
| PluginMail | 130 |
| PluginMessageRenderer | 117 |
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
| PluginToolManager | 36 |
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
| PluginLLMProviderMiniMax | 23 |
| PluginMessageListZCode | 21 |
| … 102 more modules | 616 |
| **Total** | **2817** |

## Catalogs missing `en` for some keys

| Catalog | keys missing en | total keys |
|---|---|---|
| Packages/PluginAppStoreConnect/Resources/Localizable.xcstrings | 279 | 286 |
| Packages/PluginACP/Resources/Localizable.xcstrings | 34 | 95 |
| Packages/PluginDatabaseManager/Resources/Localizable.xcstrings | 31 | 156 |
| Packages/PluginMail/Resources/Localizable.xcstrings | 28 | 30 |
| Packages/PluginSettingGeneral/Resources/Localizable.xcstrings | 28 | 52 |
| Packages/PluginAppStorePromoDesigner/Resources/Localizable.xcstrings | 22 | 76 |
| Packages/PluginSystemBenchmark/Resources/Localizable.xcstrings | 14 | 49 |
| Packages/PluginTextActions/Resources/Localizable.xcstrings | 12 | 53 |
| Packages/PluginMessageRenderer/Resources/Localizable.xcstrings | 10 | 60 |
| Vendor/LumiUI/Resources/Localizable.xcstrings | 9 | 108 |
| Packages/PluginModelSelector/Resources/Localizable.xcstrings | 8 | 31 |
| Packages/PluginLLMProviderSettings/Resources/Localizable.xcstrings | 8 | 71 |
| Packages/PluginConversationList/Resources/Localizable.xcstrings | 8 | 25 |
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
   ToolManager settings surfaces.
3. **Providers**: provider metadata visible in pickers (names, descriptions),
   ModelSelector, and MLX provider plugin strings ("MLX 本地供应商" etc.).
4. **Tools & permission prompts**: tool schema descriptions rendered in prompts,
   PluginToolManager manager UI + permission dialogs (this text also reaches
   the LLM; keep changes semantics-preserving).
5. **Errors & agent-loop UI**: non-localized throw/error strings shown to the
   user, agent loop event titles (e.g. "生成中"/"结束"), send-state strings.
6. **Plugin long tail** (several PRs, roughly by visibility):
   Browser/DiskManager/ClipboardManager/AppManager → Mail/MessageRenderer →
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
