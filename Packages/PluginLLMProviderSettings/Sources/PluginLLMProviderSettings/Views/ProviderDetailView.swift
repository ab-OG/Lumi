import Foundation
import LumiUI
import KitLLM
import SwiftUI

/// 单个供应商的详情视图（API Key 段 + 模型段）。
///
/// - 云端供应商：API Key 读写/删除 + 模型列表（点击切换选中模型）；
/// - 本地供应商：仅模型列表（无需 API Key）。
///
/// View 只依赖 `ProviderDetailViewModel`，不再直接持有 manager / Provider / Store，
/// 也不对外部 Provider 做 downcast（下载能力由 ViewModel 解析）。
@MainActor
public struct ProviderDetailView: View {
    @LumiTheme private var theme

    @ObservedObject private var viewModel: ProviderDetailViewModel
    @State private var isEditorPresented = false
    @State private var isDeleteConfirmationPresented = false
    /// 复制 API Key 后短暂显示「已复制」反馈。
    @State private var isAPIKeyCopied = false

    init(viewModel: ProviderDetailViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            if !viewModel.isLocal {
                apiKeySection
            }
            if let downloadViewModel = viewModel.downloadViewModel,
               let capability = viewModel.downloadCapability {
                ProviderModelDownloadView(
                    models: viewModel.models,
                    capability: capability,
                    viewModel: downloadViewModel,
                    onSelectModel: { modelID in
                        viewModel.select(modelID: modelID)
                    },
                    isModelSelected: { modelID in
                        viewModel.isModelSelected(modelID)
                    }
                )
            } else {
                modelSection
            }
            if let modelRefreshError = viewModel.modelRefreshError {
                AppErrorBanner(message: LocalizedStringKey(modelRefreshError))
            }
            if let customProviderRemoveError = viewModel.customProviderRemoveError {
                AppErrorBanner(message: LocalizedStringKey(customProviderRemoveError))
            }
        }
        .sheet(isPresented: $isEditorPresented) {
            if let editor = viewModel.makeCustomProviderEditor() {
                editor
                    .frame(width: 580, height: 640)
            }
        }
        .confirmationDialog(
            pluginLocalization.string("Delete custom provider?"),
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(pluginLocalization.string("Delete"), role: .destructive) {
                viewModel.removeCustomProvider()
            }
            Button(pluginLocalization.string("Cancel"), role: .cancel) {}
        } message: {
            Text(pluginLocalization.string("This removes the provider configuration and its API key."))
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isLocal ? "cpu" : "cloud.fill")
                    .font(.title3)
                    .foregroundStyle(theme.primary)
                Text(viewModel.displayName)
                    .font(.appTitle)
                Spacer()
                if let url = viewModel.websiteURL {
                    Link(destination: url) {
                        AppTag(pluginLocalization.string("Visit Website"), systemImage: "arrow.up.right.square", style: .accent)
                    }
                    .buttonStyle(.plain)
                }
                if viewModel.canEditCustomProvider {
                    AppButton(pluginLocalization.string("Edit"), systemImage: "pencil", style: .secondary, size: .small) {
                        isEditorPresented = true
                    }
                    .accessibilityIdentifier(ProviderSettingsAccessibility.editProviderButton)
                    AppButton(pluginLocalization.string("Delete"), systemImage: "trash", style: .destructive, size: .small) {
                        isDeleteConfirmationPresented = true
                    }
                }
                if viewModel.canRefreshModels {
                    AppButton(
                        viewModel.isRefreshingModels
                            ? pluginLocalization.string("Refreshing…")
                            : pluginLocalization.string("Refresh Models"),
                        systemImage: "arrow.clockwise",
                        style: .secondary,
                        size: .small
                    ) {
                        Task { await viewModel.refreshModels() }
                    }
                    .disabled(viewModel.isRefreshingModels)
                    .help(pluginLocalization.string("Fetch the latest model list from the provider"))
                    .accessibilityIdentifier(ProviderSettingsAccessibility.refreshModelsButton)
                }
            }
            if !viewModel.providerDescription.isEmpty {
                Text(viewModel.providerDescription)
                    .font(.appCaption)
                    .foregroundStyle(theme.textSecondary)
            }
            Text(viewModel.providerID)
                .font(.appMicro)
                .foregroundStyle(theme.textTertiary)
                .textSelection(.enabled)
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        AppSettingSection(title: pluginLocalization.string("API Key")) {
            VStack(spacing: 0) {
                AppSettingRow(
                    title: "API Key",
                    description: pluginLocalization.string("Configure access credentials"),
                    icon: "key"
                ) {
                    HStack(spacing: 6) {
                        Group {
                            if viewModel.isAPIKeyRevealed {
                                TextField(pluginLocalization.string("Enter API Key"), text: $viewModel.apiKey)
                            } else {
                                SecureField(pluginLocalization.string("Enter API Key"), text: $viewModel.apiKey)
                            }
                        }
                        .textFieldStyle(.plain)
                        .font(.appBody)
                        .frame(width: 260)
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                AppSettingRow(
                    title: pluginLocalization.string("Actions"),
                    description: viewModel.savedAPIKey.isEmpty
                        ? pluginLocalization.string("No API key saved")
                        : pluginLocalization.string("API key saved")
                ) {
                    HStack(spacing: 8) {
                        if !viewModel.savedAPIKey.isEmpty {
                            AppIconButton(
                                systemImage: viewModel.isAPIKeyRevealed ? "eye.slash" : "eye"
                            ) {
                                viewModel.isAPIKeyRevealed.toggle()
                            }
                            .help(pluginLocalization.string(viewModel.isAPIKeyRevealed ? "Hide API Key" : "Show API Key"))
                        }

                        if !copyableAPIKey.isEmpty {
                            AppIconButton(
                                systemImage: isAPIKeyCopied ? "checkmark" : "doc.on.doc",
                                tint: isAPIKeyCopied ? theme.success : nil
                            ) {
                                copyAPIKey()
                            }
                            .help(pluginLocalization.string(isAPIKeyCopied ? "Copied" : "Copy API Key"))
                            .accessibilityIdentifier(ProviderSettingsAccessibility.copyAPIKeyButton)
                        }

                        AppButton(pluginLocalization.string("Save"), systemImage: "checkmark", style: .primary, size: .small) {
                            viewModel.saveAPIKey()
                        }
                        .disabled(
                            viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || viewModel.apiKey == viewModel.savedAPIKey
                        )

                        if !viewModel.savedAPIKey.isEmpty {
                            AppButton(pluginLocalization.string("Delete"), systemImage: "trash", style: .destructive, size: .small) {
                                viewModel.removeAPIKey()
                            }
                        }

                        if !viewModel.savedAPIKey.isEmpty, viewModel.apiKey == viewModel.savedAPIKey {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.success)
                                    .font(.appCaption)
                                Text(pluginLocalization.string("Saved"))
                                    .font(.appCaption)
                                    .foregroundColor(theme.success)
                            }
                        }
                    }
                }

                if let apiKeySaveError = viewModel.apiKeySaveError {
                    Divider()
                        .padding(.vertical, 8)

                    AppSettingRow(
                        title: pluginLocalization.string("Error"),
                        description: apiKeySaveError
                    ) {
                        EmptyView()
                    }
                    .foregroundColor(theme.error)
                }
            }
        }
    }

    // MARK: - Model Section

    private var modelSection: some View {
        AppSettingSection(title: pluginLocalization.string("Available Models")) {
            VStack(spacing: 0) {
                ForEach(viewModel.models.enumerated().map({ $0 }), id: \.element.id) { index, model in
                    if index > 0 {
                        Divider()
                            .padding(.vertical, 4)
                    }
                    modelRow(model)
                }
            }
        }
    }

    private func modelRow(_ model: LLMModelInfo) -> some View {
        let isSelected = viewModel.isModelSelected(model.id)
        return AppSettingRow(
            title: model.displayName,
            description: model.contextWindowSize.map {
                String(format: pluginLocalization.string("Context %@"), Self.formatted($0))
            },
            icon: isSelected ? "checkmark.circle.fill" : (model.supportsVision ? "eye" : "cpu")
        ) {
            HStack(spacing: 6) {
                if model.supportsVision {
                    AppTag(pluginLocalization.string("Vision"), systemImage: "eye", style: .accent)
                }
                if isSelected {
                    AppTag(pluginLocalization.string("Current"), systemImage: "checkmark", style: .accent)
                }
            }
        }
        .onTapGesture {
            viewModel.select(modelID: model.id)
        }
    }

    // MARK: - Helpers

    /// 可复制的 API Key：优先已保存的值，无已保存值时复制输入框里的当前内容。
    private var copyableAPIKey: String {
        let saved = viewModel.savedAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !saved.isEmpty {
            return saved
        }
        return viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func copyAPIKey() {
        let value = copyableAPIKey
        guard !value.isEmpty else { return }
        LumiPasteboard.copyString(value)
        isAPIKeyCopied = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            isAPIKeyCopied = false
        }
    }

    private static func formatted(_ tokens: Int) -> String {
        if tokens >= 1_000_000 {
            let m = Double(tokens) / 1_000_000
            return String(format: "%.1fM", m)
        }
        if tokens >= 1_000 {
            return "\(tokens / 1_000)K"
        }
        return "\(tokens)"
    }
}
