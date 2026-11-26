import LumiLocalizationKit

public let pluginLocalization = PluginLocalization(bundle: .module)

extension PluginLocalization {
    /// Selects a separate flat catalog key for singular and plural counts.
    public func count(_ singular: String, _ plural: String, for count: Int) -> String {
        string(count == 1 ? singular : plural)
    }
}
