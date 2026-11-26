import Foundation
import Testing

@Suite("Computer Use authorization localization integrity")
struct ComputerUseLocalizationIntegrityTests {
    private static let requiredLanguages = ["en", "zh-Hans", "zh-Hant", "zh-HK", "zh-TW"]
    private static let key = "Control of {app} is not allowed. Add it under Lumi Settings > Computer Use."

    @Test("disallowed app message has five translations and preserves its placeholder")
    func disallowedAppMessageIsLocalized() throws {
        let catalogURL = try #require(Self.catalogURL(), "Computer Use catalog not found")
        let data = try Data(contentsOf: catalogURL)
        let root = try #require(
            try JSONSerialization.jsonObject(with: data) as? [String: Any],
            "Computer Use catalog root is not a JSON object"
        )
        let strings = try #require(root["strings"] as? [String: Any], "Computer Use catalog has no strings")
        let entry = try #require(strings[Self.key] as? [String: Any], "Disallowed app message is missing")
        let localizations = try #require(
            entry["localizations"] as? [String: Any],
            "Disallowed app message has no localizations"
        )

        for language in Self.requiredLanguages {
            let localization = try #require(
                localizations[language] as? [String: Any],
                "Missing translation for \(language)"
            )
            let stringUnit = try #require(
                localization["stringUnit"] as? [String: Any],
                "Missing string unit for \(language)"
            )
            let value = try #require(stringUnit["value"] as? String, "Missing text for \(language)")
            #expect(!value.isEmpty)
            #expect(value.components(separatedBy: "{app}").count - 1 == 1)
            if language == "en" {
                #expect(value == Self.key)
            }
        }
    }

    private static func catalogURL() -> URL? {
        var directory = URL(fileURLWithPath: #filePath)
        // Tests/ComputerUsePluginTests/<file> → package root.
        for _ in 0..<3 {
            directory.deleteLastPathComponent()
        }
        let url = directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("Localizable.xcstrings")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
