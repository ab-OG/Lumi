import SwiftUI
import LumiUI
import KitMail

/// 邮件账户设置页：账户列表 + 添加/编辑入口。
///
/// 布局遵循 settings-ui 规范：`PluginSettingsScaffold` + 原生 `AppSettingSection` /
/// `AppSettingRow`，不使用 `Form`。
public struct MailSettingsView: View {
    @LumiTheme private var theme: any LumiUITheme

    private let sessionManager: MailSessionManager
    private let accountStore: MailAccountStore

    /// 当前展示的编辑草稿（非 nil 时展示表单）。
    @State private var editingDraft: MailAccountDraft?
    /// 正在编辑的账户 id（新增为 nil）。
    @State private var editingAccountID: UUID?
    @State private var accounts: [MailAccountConfig] = []
    /// 连接测试中的账户 id（展示进度）。
    @State private var testingAccountID: UUID?
    @State private var errorMessage: String?

    public init(sessionManager: MailSessionManager, accountStore: MailAccountStore) {
        self.sessionManager = sessionManager
        self.accountStore = accountStore
    }

    public var body: some View {
        PluginSettingsScaffold(
            title: pluginLocalization.string("Mail"),
            subtitle: pluginLocalization.string("IMAP/SMTP accounts: connection, composing, search, and Agent tools."),
            showHeader: true
        ) {
            if editingDraft != nil {
                formCard
            } else {
                accountListCard
                addCard
            }
        }
        .task {
            reloadAccounts()
        }
    }

    // MARK: - 账户列表

    private var accountListCard: some View {
        AppSettingSection(title: pluginLocalization.string("Accounts"), titleAlignment: .leading) {
            VStack(spacing: 0) {
                if accounts.isEmpty {
                    Text(pluginLocalization.string("No mail accounts yet. Click Add Account below to get started."))
                        .font(.appBody)
                        .foregroundColor(theme.textSecondary)
                } else {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                        if index > 0 {
                            Divider()
                                .padding(.vertical, 8)
                        }
                        accountRow(account)
                    }
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.appCaption)
                        .foregroundColor(theme.error)
                }
            }
        }
    }

    private func accountRow(_ account: MailAccountConfig) -> some View {
        AppSettingRow(
            title: account.displayName,
            description: "\(account.email) · \(account.imapHost)",
            icon: "envelope"
        ) {
            HStack(spacing: 8) {
                if testingAccountID == account.id {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    AppButton(pluginLocalization.string("Test"), style: .secondary, size: .small) {
                        Task { await testConnection(account) }
                    }
                }
                AppButton(pluginLocalization.string("Edit"), style: .secondary, size: .small) {
                    beginEditing(account)
                }
                AppButton(pluginLocalization.string("Delete"), style: .destructive, size: .small) {
                    delete(account)
                }
            }
        }
    }

    // MARK: - 添加入口

    private var addCard: some View {
        AppSettingSection(title: nil, titleAlignment: .leading) {
            AppButton(pluginLocalization.string("Add Account"), style: .primary, fillsWidth: true) {
                beginAdding()
            }
        }
    }

    // MARK: - 表单

    @ViewBuilder
    private var formCard: some View {
        if let draft = editingDraft {
            MailAccountFormView(
                initialDraft: draft,
                accountID: editingAccountID,
                sessionManager: sessionManager,
                onSave: { save($0) },
                onCancel: {
                    editingDraft = nil
                    editingAccountID = nil
                }
            )
        }
    }

    // MARK: - 操作

    private func reloadAccounts() {
        accounts = accountStore.loadAccounts()
    }

    private func beginAdding() {
        editingAccountID = nil
        editingDraft = MailAccountDraft.forNewAccount()
    }

    private func beginEditing(_ account: MailAccountConfig) {
        editingAccountID = account.id
        editingDraft = MailAccountDraft(
            config: account,
            password: accountStore.password(for: account.id)
        )
    }

    private func save(_ draft: MailAccountDraft) {
        let id = editingAccountID ?? UUID()
        guard let config = try? draft.toConfig(id: id) else {
            errorMessage = pluginLocalization.string("IMAP and SMTP ports must be between 1 and 65535.")
            return
        }
        accountStore.upsertAccount(config)
        accountStore.setPassword(draft.password, for: id)
        // 若编辑了已连接账户的凭据/主机，断开以强制下次重建会话。
        Task {
            await sessionManager.disconnect(accountID: id)
        }
        editingDraft = nil
        editingAccountID = nil
        reloadAccounts()
    }

    private func delete(_ account: MailAccountConfig) {
        accountStore.deleteAccount(id: account.id)
        Task {
            await sessionManager.disconnect(accountID: account.id)
        }
        reloadAccounts()
    }

    private func testConnection(_ account: MailAccountConfig) async {
        testingAccountID = account.id
        errorMessage = nil
        defer { testingAccountID = nil }
        guard let password = accountStore.password(for: account.id) else {
            errorMessage = pluginLocalization.string("No password found for this account. Edit it and save a password first.")
            return
        }
        do {
            try await sessionManager.testConnection(account: account, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
