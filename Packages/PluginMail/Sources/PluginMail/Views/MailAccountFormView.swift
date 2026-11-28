import SwiftUI
import LumiUI
import KitMail

/// 账户添加/编辑表单。
///
/// - 服务商预设选择后自动预填 IMAP/SMTP 主机与端口；
/// - 「连接测试」用当前表单值临时建会话（不保存），成功/失败即时反馈；
/// - 保存时密码经 `MailAccountStore` 写入 Keychain，配置 JSON 不含密码。
public struct MailAccountFormView: View {
    @LumiTheme private var theme: any LumiUITheme

    @State private var draft: MailAccountDraft
    private let accountID: UUID?
    private let sessionManager: MailSessionManager
    private let onSave: (MailAccountDraft) -> Void
    private let onCancel: () -> Void

    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var formError: String?

    private enum TestResult: Equatable {
        case success(String)
        case failure(String)
    }

    public init(
        initialDraft: MailAccountDraft,
        accountID: UUID?,
        sessionManager: MailSessionManager,
        onSave: @escaping (MailAccountDraft) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._draft = State(initialValue: initialDraft)
        self.accountID = accountID
        self.sessionManager = sessionManager
        self.onSave = onSave
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            AppSettingSection(
                title: accountID == nil ? pluginLocalization.string("Add Account") : pluginLocalization.string("Edit Account"),
                titleAlignment: .leading
            ) {
                providerRow
            }

            AppSettingSection(title: pluginLocalization.string("Account Details"), titleAlignment: .leading) {
                VStack(spacing: 0) {
                    AppSettingRow(title: pluginLocalization.string("Display Name (Optional)")) {
                        AppInputField(LocalizedStringKey(pluginLocalization.string("Display Name (Optional)")), text: $draft.displayName)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    AppSettingRow(title: pluginLocalization.string("Email Address")) {
                        AppInputField(LocalizedStringKey(pluginLocalization.string("Email Address")), text: $draft.email)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    AppSettingRow(title: pluginLocalization.string("Login Username")) {
                        AppInputField(LocalizedStringKey(pluginLocalization.string("Login Username")), text: $draft.username)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    AppSettingRow(title: pluginLocalization.string("Password / App Password")) {
                        GlassTextField(
                            title: "",
                            text: $draft.password,
                            placeholder: pluginLocalization.string("App-specific password or auth code"),
                            isSecure: true,
                            allowsReveal: true
                        )
                    }
                }
            }

            AppSettingSection(title: pluginLocalization.string("Servers"), titleAlignment: .leading) {
                VStack(spacing: 0) {
                    serverHostRow(pluginLocalization.string("IMAP Server"), host: $draft.imapHost)

                    Divider()
                        .padding(.vertical, 8)

                    portRow(pluginLocalization.string("IMAP Port"), port: $draft.imapPort)

                    Divider()
                        .padding(.vertical, 8)

                    serverHostRow(pluginLocalization.string("SMTP Server"), host: $draft.smtpHost)

                    Divider()
                        .padding(.vertical, 8)

                    portRow(pluginLocalization.string("SMTP Port"), port: $draft.smtpPort)

                    Divider()
                        .padding(.vertical, 8)

                    AppSettingToggleRow(pluginLocalization.string("Require TLS"), isOn: $draft.useTLS)
                }
            }

            AppSettingSection(title: nil, titleAlignment: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    testRow
                    if let formError {
                        Text(formError)
                            .font(.appCaption)
                            .foregroundColor(theme.error)
                    }
                    actionsRow
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 服务商预设

    private var providerRow: some View {
        AppSettingRow(title: pluginLocalization.string("Provider"), icon: "server.rack") {
            Picker(pluginLocalization.string("Provider"), selection: $draft.provider) {
                ForEach(MailProviderPreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
        .onChange(of: draft.provider) { newValue in
            draft.applyPresetDefaults()
        }
    }

    // MARK: - 服务器字段

    private func serverHostRow(_ title: String, host: Binding<String>) -> some View {
        AppSettingRow(title: title) {
            AppInputField(LocalizedStringKey(title), text: host)
        }
    }

    private func portRow(_ title: String, port: Binding<Int>) -> some View {
        AppSettingRow(title: title) {
            VStack(alignment: .leading, spacing: 4) {
                TextField(
                    title,
                    value: port,
                    format: .number
                )
                .textFieldStyle(.plain)
                if !MailAccountDraft.isValidPort(port.wrappedValue) {
                    Text(pluginLocalization.string("Port must be between 1 and 65535."))
                        .font(.appCaption)
                        .foregroundColor(theme.error)
                }
            }
        }
    }

    // MARK: - 连接测试

    private var testRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                AppButton(
                    isTesting ? pluginLocalization.string("Testing…") : pluginLocalization.string("Test Connection"),
                    style: .secondary,
                    fillsWidth: true
                ) {
                    Task { await runTest() }
                }
                .disabled(isTesting)
                if isTesting {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            resultBanner
        }
    }

    @ViewBuilder
    private var resultBanner: some View {
        if let testResult {
            switch testResult {
            case .success(let message):
                Text("✓ \(message)")
                    .font(.appCaption)
                    .foregroundColor(theme.success)
            case .failure(let message):
                Text("⚠ \(message)")
                    .font(.appCaption)
                    .foregroundColor(theme.error)
            }
        }
    }

    // MARK: - 操作

    private var actionsRow: some View {
        HStack(spacing: 8) {
            AppButton(pluginLocalization.string("Cancel"), style: .secondary, fillsWidth: true) {
                onCancel()
            }
            AppButton(
                pluginLocalization.string("Save"),
                style: .primary,
                fillsWidth: true
            ) {
                save()
            }
        }
    }

    private func runTest() async {
        isTesting = true
        testResult = nil
        formError = nil
        defer { isTesting = false }

        guard !draft.email.isEmpty, !draft.password.isEmpty else {
            formError = pluginLocalization.string("Enter an email address and password/auth code first.")
            return
        }
        guard draft.hasValidPorts else {
            formError = pluginLocalization.string("IMAP and SMTP ports must be between 1 and 65535.")
            return
        }
        guard let config = try? draft.toConfig(id: accountID ?? UUID()) else {
            formError = pluginLocalization.string("IMAP and SMTP ports must be between 1 and 65535.")
            return
        }
        do {
            try await sessionManager.testConnection(account: config, password: draft.password)
            testResult = .success(pluginLocalization.string("Connection succeeded: authentication passed."))
        } catch {
            testResult = .failure(String(format: pluginLocalization.string("Connection failed: %@"), error.localizedDescription))
        }
    }

    private func save() {
        formError = nil
        guard !draft.email.isEmpty else {
            formError = pluginLocalization.string("Email address cannot be empty.")
            return
        }
        guard !draft.password.isEmpty else {
            formError = pluginLocalization.string("Enter a password/auth code.")
            return
        }
        guard !draft.imapHost.isEmpty, !draft.smtpHost.isEmpty else {
            formError = pluginLocalization.string("IMAP and SMTP servers cannot be empty.")
            return
        }
        guard draft.hasValidPorts else {
            formError = pluginLocalization.string("IMAP and SMTP ports must be between 1 and 65535.")
            return
        }
        onSave(draft)
    }
}
