import SwiftUI

public struct AppLoadingOverlay: View {
    @LumiTheme private var theme

    public enum Size {
        case small
        case medium
        case large
    }

    let message: LocalizedStringKey?
    let size: Size

    public init(size: Size = .medium) {
        self.message = nil
        self.size = size
    }

    public init(message: LocalizedStringKey, size: Size = .medium) {
        self.message = message
        self.size = size
    }

    /// Verbatim overload for callers that resolve their localized string first
    /// (e.g. plugin `pluginLocalization` shims) and must not be re-looked-up.
    public init(verbatimMessage: String, size: Size = .medium) {
        self.message = nil
        self.verbatimMessage = verbatimMessage
        self.size = size
    }

    private var verbatimMessage: String? = nil

    public var body: some View {
        VStack(spacing: AppUI.Spacing.md) {
            ProgressView()
                .scaleEffect(scaleEffect)

            if let verbatimMessage {
                Text(verbatimMessage)
                    .font(AppUI.Typography.caption1)
                    .foregroundColor(theme.textSecondary)
            } else if let message {
                Text(message)
                    .font(AppUI.Typography.caption1)
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var scaleEffect: CGFloat {
        switch size {
        case .small: 0.8
        case .medium: 1.0
        case .large: 1.5
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.15)
            .frame(width: 300, height: 200)
        AppLoadingOverlay(size: .small)
    }
}

#Preview("With Message") {
    ZStack {
        Color.gray.opacity(0.15)
            .frame(width: 300, height: 200)
        AppLoadingOverlay(message: "Loading data…", size: .medium)
    }
}

#Preview("Large") {
    ZStack {
        Color.gray.opacity(0.15)
            .frame(width: 300, height: 300)
        AppLoadingOverlay(message: "Processing…", size: .large)
    }
}
