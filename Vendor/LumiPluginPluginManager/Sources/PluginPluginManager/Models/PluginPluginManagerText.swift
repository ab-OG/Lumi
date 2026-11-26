import KernelCore
import Foundation

/// User-facing string constants for the Plugin Manager screen.
///
/// All strings are resolved through `pluginLocalization` so that the
/// existing `LumiLocalizationKit` / xcstrings pipeline handles language
/// selection.  English is the source language; Chinese translations live
/// in `Resources/Localizable.xcstrings`.
enum PluginPluginManagerText {
    static var plugins: String { pluginLocalization.string("Plugin Manager") }
    static var pluginsHint: String { pluginLocalization.string("Manage all registered plugins") }
    static var aboutDescription: String { pluginLocalization.string("Browse all registered plugins.") }
    static var searchPlugins: String { pluginLocalization.string("Search plugins") }
    static var noPluginsFound: String { pluginLocalization.string("No plugins found") }
    static var selectPlugin: String { pluginLocalization.string("Select a plugin") }
    static var status: String { pluginLocalization.string("Status") }
    static func pluginsCountText(_ count: Int) -> String {
        String(format: pluginLocalization.count("%lld plugin", "%lld plugins", for: count), count)
    }
    static func enabledCountText(_ count: Int) -> String {
        String(format: pluginLocalization.count("%lld enabled item", "%lld enabled", for: count), count)
    }
    static var allCategories: String { pluginLocalization.string("All") }
    static var filterAll: String { pluginLocalization.string("All") }
    static var filterEnabled: String { pluginLocalization.string("Enabled") }
    static var filterDisabled: String { pluginLocalization.string("Disabled") }
    static var alwaysOn: String { pluginLocalization.string("Always On") }
    static var disabled: String { pluginLocalization.string("Disabled") }
    static var disabledPermanently: String { pluginLocalization.string("Deactivated") }
    static var enabled: String { pluginLocalization.string("Enabled") }
    static var noDetailsProvided: String { pluginLocalization.string("No details provided") }
    static var noDetailsHint: String { pluginLocalization.string("The plugin author did not provide a details view.") }
    static var enable: String { pluginLocalization.string("Enable") }
    static var disableAll: String { pluginLocalization.string("Disable All") }
    static var disablingAll: String { pluginLocalization.string("Disabling All...") }

    // Detail panel info
    static var categoryLabel: String { pluginLocalization.string("Category") }
    static var versionLabel: String { pluginLocalization.string("Version") }
    static var policyLabel: String { pluginLocalization.string("Policy") }
    static var identifierLabel: String { pluginLocalization.string("Identifier") }
    static var permissionsTitle: String { pluginLocalization.string("Permissions") }
    static var stageLabel: String { pluginLocalization.string("Stage") }
    static var aboutViewLabel: String { pluginLocalization.string("About View") }
    static var dismiss: String { pluginLocalization.string("Dismiss") }

    // About view / landing page
    static var browsePlugins: String { pluginLocalization.string("Browse Plugins") }
    static var coreCapabilities: String { pluginLocalization.string("Core Capabilities") }
    static var whereToFindIt: String { pluginLocalization.string("Where to Find It") }
    static var settingsEntry: String { pluginLocalization.string("Settings → Plugin Manager") }
    static var capabilityCatalogTitle: String { pluginLocalization.string("Plugin Catalog") }
    static var capabilityCatalogDescription: String { pluginLocalization.string("Browse all registered plugins.") }
    static var capabilitySearchTitle: String { pluginLocalization.string("Search") }
    static var capabilitySearchDescription: String { pluginLocalization.string("Search by name instantly.") }
    static var capabilityFilterTitle: String { pluginLocalization.string("Category Filter") }
    static var capabilityFilterDescription: String { pluginLocalization.string("Filter by plugin category.") }
    static var capabilityDetailTitle: String { pluginLocalization.string("Plugin Details") }
    static var capabilityDetailDescription: String { pluginLocalization.string("View each plugin's description and stage.") }
    static var capabilityOrderTitle: String { pluginLocalization.string("Order") }
    static var capabilityOrderDescription: String { pluginLocalization.string("Plugins are listed in registration order.") }
}

// MARK: - Display names for KernelCore enums

extension PluginCategory {
    /// Display order for the category filter tab bar.
    static var displayOrder: [PluginCategory] {
        [
            .core, .chat, .llm, .system, .project, .feature, .editor,
            .integration, .design, .general,
        ]
    }

    var displayName: String {
        switch self {
        case .core: pluginLocalization.string("Core")
        case .chat: pluginLocalization.string("Chat")
        case .llm: pluginLocalization.string("Models")
        case .editor: pluginLocalization.string("Editor")
        case .project: pluginLocalization.string("Projects")
        case .feature: pluginLocalization.string("Features")
        case .system: pluginLocalization.string("System")
        case .design: pluginLocalization.string("Design")
        case .integration: pluginLocalization.string("Integrations")
        case .general: pluginLocalization.string("General")
        }
    }

    var systemImage: String {
        switch self {
        case .core: "cube"
        case .chat: "bubble.left.and.bubble.right"
        case .llm: "cpu"
        case .editor: "chevron.left.forwardslash.chevron.right"
        case .project: "folder"
        case .feature: "square.grid.2x2"
        case .system: "desktopcomputer"
        case .design: "paintbrush"
        case .integration: "arrow.up.right.square"
        case .general: "puzzlepiece.extension"
        }
    }

    var sortOrder: Int {
        switch self {
        case .core: 10
        case .chat: 15
        case .llm: 20
        case .system: 25
        case .project: 30
        case .feature: 32
        case .editor: 35
        case .integration: 40
        case .design: 45
        case .general: 50
        }
    }
}

extension PluginStage {
    var displayName: String {
        switch self {
        case .experimental: pluginLocalization.string("Experimental")
        case .preview: pluginLocalization.string("Preview")
        case .stable: pluginLocalization.string("Stable")
        case .deprecated: pluginLocalization.string("Deprecated")
        }
    }
}
