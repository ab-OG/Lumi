import LumiUI
import ProviderAppUpdate
import ProviderDocsView
import ProviderUninstall
import SwiftUI
import UniformTypeIdentifiers

/// 通用设置详情视图 —— 设置窗口「通用」标签页：四个分组卡片。
///
/// 只依赖 `GeneralSettingsViewModel`；诊断导出、更新通道、卸载扫描等
/// 业务状态全部由 ViewModel 提供，外部操作经 Capability 收敛。
struct GeneralSettingsDetailView: View {
    let version: String?
    @ObservedObject var viewModel: GeneralSettingsViewModel

    /// 是否展示说明书浏览器（纯 UI 状态）。
    @State private var isPresentingManuals = false
    /// 是否展示卸载确认弹窗（纯 UI 状态）。
    @State private var isPresentingUninstall = false

    /// App bundle 元数据（名称 / 包名 / 版本 / 构建）。
    private let bundleInfo = AppBundleInfo()

    var body: some View {
        AppSettingsContentScaffold(maxContentWidth: nil) {
            VStack(alignment: .leading, spacing: 24) {
                manualsSection
                lumiSection
                updatesSection
                cliSection
                diagnosticsSection
                uninstallSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $isPresentingManuals) {
            if !viewModel.manuals.isEmpty {
                ManualsBrowserView(manuals: viewModel.manuals)
            }
        }
        .sheet(isPresented: $isPresentingUninstall, onDismiss: {
            viewModel.cancelUninstallScan()
        }) {
            uninstallSheet
        }
    }

    // MARK: - 说明书

    private var manualsSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("User Manual"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("User Manual"),
                description: pluginLocalization.string("Usage guides for each feature."),
                icon: "book"
            ) {
                AppButton(
                    pluginLocalization.string("Open"),
                    systemImage: "book.pages",
                    style: .secondary,
                    size: .small
                ) {
                    isPresentingManuals = true
                }
            }
        }
    }

    // MARK: - Lumi（应用信息）

    private var lumiSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Lumi"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Name"),
                    description: bundleInfo.name,
                    icon: "app"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: "Bundle ID",
                    description: bundleInfo.bundleIdentifier,
                    icon: "number"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Version"),
                    description: bundleInfo.version ?? "Not Set",
                    icon: "info.circle"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Build"),
                    description: bundleInfo.build ?? "Not Set",
                    icon: "hammer"
                ) {
                    EmptyView()
                }
                Divider()
                    .padding(.vertical, 8)
                AppSettingRow(
                    title: pluginLocalization.string("Storage Size"),
                    description: viewModel.storageSizeDescription,
                    icon: "internaldrive"
                ) {
                    AppButton(
                        pluginLocalization.string("Open Database Folder"),
                        systemImage: "folder",
                        style: .secondary,
                        size: .small
                    ) {
                        viewModel.openStorageDirectory()
                    }
                    .disabled(!viewModel.isStorageAvailable)
                }
            }
        }
    }

    // MARK: - 更新

    /// `allowsAppUpdates` 的宿主（Lumi 直营）展示「检查更新」行，
    /// 点击广播 `checkForUpdates` 通知，由宿主（如 Sparkle 更新插件）消费。
    private var updatesSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Updates"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Check for Updates"),
                    description: "Check whether a newer version of Lumi is available.",
                    icon: "arrow.down.circle"
                ) {
                    AppButton(
                        pluginLocalization.string("Check..."),
                        systemImage: "arrow.triangle.2.circlepath",
                        style: .secondary,
                        size: .small
                    ) {
                        viewModel.checkForUpdates()
                    }
                }

                if viewModel.isUpdateChannelAvailable {
                    Divider()
                        .padding(.vertical, 8)

                    AppSettingRow(
                        title: pluginLocalization.string("Update Channel"),
                        description: viewModel.selectedUpdateChannel == .preview
                            ? pluginLocalization.string("Get preview builds from the pre branch. They may contain unfixed issues.")
                            : pluginLocalization.string("Get stable builds from the main branch."),
                        icon: viewModel.selectedUpdateChannel == .preview ? "flask" : "checkmark.seal"
                    ) {
                        Picker(pluginLocalization.string("Update Channel"), selection: $viewModel.selectedUpdateChannel) {
                            Text(pluginLocalization.string("Stable")).tag(AppUpdateChannel.stable)
                            Text(pluginLocalization.string("Preview")).tag(AppUpdateChannel.preview)
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }

    // MARK: - 命令行工具

    /// `lumi` 命令的安装分区。
    private var cliSection: some View {
        CLIInstallDetailView()
    }

    // MARK: - 诊断日志

    private var diagnosticsSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Diagnostic Logs"),
            titleAlignment: .leading
        ) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: pluginLocalization.string("Export Logs"),
                    description: pluginLocalization.string("Package recent logs to attach to problem reports."),
                    icon: "doc.badge.arrow.up"
                ) {
                    AppButton(
                        viewModel.isExportingDiagnostics ? pluginLocalization.string("Exporting…") : pluginLocalization.string("Export"),
                        systemImage: viewModel.isExportingDiagnostics ? "hourglass" : "square.and.arrow.up",
                        style: .secondary,
                        size: .small
                    ) {
                        viewModel.exportDiagnostics()
                    }
                    .disabled(viewModel.isExportingDiagnostics || !viewModel.isDiagnosticsAvailable)
                }

                if let diagnosticsFeedback = viewModel.diagnosticsFeedback {
                    Divider()
                        .padding(.vertical, 8)
                    Text(diagnosticsFeedback)
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - 卸载 Lumi

    private var uninstallSection: some View {
        AppSettingSection(
            title: pluginLocalization.string("Uninstall Lumi"),
            titleAlignment: .leading
        ) {
            AppSettingRow(
                title: pluginLocalization.string("Completely Uninstall Lumi"),
                description: pluginLocalization.string("Remove Lumi's plugin data, preferences, extension data, and optional credentials."),
                icon: "trash"
            ) {
                AppButton(
                    pluginLocalization.string("Uninstall Lumi"),
                    systemImage: "trash",
                    style: .destructive,
                    size: .small
                ) {
                    viewModel.beginUninstall()
                    isPresentingUninstall = true
                }
            }
        }
    }

    private var uninstallSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(pluginLocalization.string("Completely Uninstall Lumi"))
                .font(.appTitle)

            Text(pluginLocalization.string("This permanently deletes data Lumi stored itself. Your projects, source code, and exported files are not deleted."))
                .font(.appBody)
                .foregroundStyle(.secondary)

            if viewModel.isScanningUninstall {
                AppStatusBanner(kind: .loading, title: pluginLocalization.string("Checking Lumi data…"))
            } else if let uninstallScan = viewModel.uninstallScan {
                uninstallSummary(scan: uninstallScan)
            }

            if let uninstallFeedback = viewModel.uninstallFeedback {
                AppStatusBanner(kind: viewModel.uninstallFeedbackKind.bannerKind, title: uninstallFeedback)
                    .textSelection(.enabled)
            }

            AppDivider()

            VStack(spacing: 0) {
                AppSettingToggleRow(
                    pluginLocalization.string("Also move the Lumi app to the Trash"),
                    icon: "trash",
                    isOn: $viewModel.removeApplication
                )

                if let uninstallScan = viewModel.uninstallScan, uninstallScan.keychainTargetCount > 0 {
                    AppSettingToggleRow(
                        pluginLocalization.string("Also delete API keys, passwords, and credentials from the Keychain"),
                        icon: "key.fill",
                        isOn: $viewModel.removeKeychainCredentials
                    )
                }
            }

            HStack {
                Spacer()
                AppButton(pluginLocalization.string("Cancel"), style: .ghost, size: .small) {
                    isPresentingUninstall = false
                }
                AppButton(
                    viewModel.isUninstalling
                        ? pluginLocalization.string("Uninstalling…")
                        : (viewModel.removeApplication ? pluginLocalization.string("Delete Permanently and Uninstall") : pluginLocalization.string("Clear Data and Quit")),
                    systemImage: viewModel.isUninstalling ? "hourglass" : "trash.fill",
                    style: .destructive,
                    size: .small
                ) {
                    viewModel.performUninstall()
                }
                .disabled(
                    viewModel.isScanningUninstall
                    || viewModel.isUninstalling
                    || !viewModel.isUninstallAvailable
                )
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    @ViewBuilder
    private func uninstallSummary(scan: UninstallScan) -> some View {
        let summary = UninstallSummary(
            scan: scan,
            removeApplication: viewModel.removeApplication,
            removeKeychainCredentials: viewModel.removeKeychainCredentials
        )

        if summary.targets.isEmpty {
            Text(pluginLocalization.string("The current options delete nothing."))
                .font(.appBody)
                .foregroundStyle(.secondary)
        } else {
            AppSettingSection(
                title: String(format: pluginLocalization.count("Processing %lld Lumi data item, totaling %@.", "Processing %lld Lumi data items, totaling %@.", for: summary.targets.count), summary.targets.count, formattedBytes(summary.totalSizeInBytes)),
                titleAlignment: .leading
            ) {
                VStack(spacing: 0) {
                    ForEach(Array(summary.targets.prefix(8).enumerated()), id: \.element.id) { index, target in
                        AppSettingRow(
                            title: target.kind.displayName,
                            description: target.sizeInBytes > 0 ? formattedBytes(target.sizeInBytes) : "—",
                            icon: uninstallIcon(for: target)
                        ) {
                            EmptyView()
                        }

                        if index < min(summary.targets.count, 8) - 1 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                    }

                    if summary.targets.count > 8 {
                        Text(String(format: pluginLocalization.count("Plus %lld more item, processed together after confirmation.", "Plus %lld more items, processed together after confirmation.", for: summary.targets.count - 8), summary.targets.count - 8))
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    }
                }
            }
        }
    }

    private func uninstallIcon(for target: UninstallTarget) -> String {
        target.kind == .application ? "folder" : "key.fill"
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
