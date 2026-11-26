import Foundation
import Testing

@testable import PluginPluginManager

struct PluginManagerCountLocalizationTests {
    @Test("Plugin count selects singular only for one")
    func pluginCountSelectsCorrectKey() {
        #expect(
            PluginPluginManagerText.pluginsCountText(1)
                == String(format: pluginLocalization.string("%lld plugin"), 1)
        )
        for count in [0, 2] {
            #expect(
                PluginPluginManagerText.pluginsCountText(count)
                    == String(format: pluginLocalization.string("%lld plugins"), count)
            )
        }
    }

    @Test("Enabled count selects singular only for one")
    func enabledCountSelectsCorrectKey() {
        #expect(
            PluginPluginManagerText.enabledCountText(1)
                == String(format: pluginLocalization.string("%lld enabled item"), 1)
        )
        for count in [0, 2] {
            #expect(
                PluginPluginManagerText.enabledCountText(count)
                    == String(format: pluginLocalization.string("%lld enabled"), count)
            )
        }
    }
}
