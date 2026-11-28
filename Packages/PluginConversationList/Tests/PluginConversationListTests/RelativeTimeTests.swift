import Foundation
import Testing
@testable import PluginConversationList

@Test func relativeTimeFormatsPastMinutesHoursAndDays() {
    // 运行时 locale 因机器而异：断言与 pluginLocalization 的解析结果一致，
    // 各语言的字面值由 ConversationListCatalogMigrationIntegrityTests 兜底。
    #expect(Date(timeIntervalSinceNow: -5 * 60 - 1).relativeTime == formatRelative(5, "minute"))
    #expect(Date(timeIntervalSinceNow: -2 * 60 * 60 - 1).relativeTime == formatRelative(2, "hour"))
    #expect(Date(timeIntervalSinceNow: -3 * 24 * 60 * 60 - 1).relativeTime == formatRelative(3, "day"))
}

@Test func relativeTimeUsesSingularForCountOne() {
    #expect(Date(timeIntervalSinceNow: -60).relativeTime == formatRelative(1, "minute"))
    #expect(Date(timeIntervalSinceNow: -60 * 60).relativeTime == formatRelative(1, "hour"))
    #expect(Date(timeIntervalSinceNow: -24 * 60 * 60).relativeTime == formatRelative(1, "day"))
}

@Test func relativeTimeTreatsRecentAndFutureDatesAsJustNow() {
    #expect(Date().relativeTime == pluginLocalization.string("Just now"))
    #expect(Date(timeIntervalSinceNow: 1).relativeTime == pluginLocalization.string("Just now"))
}

/// 按运行时 locale 解析期望文案（单数/复数 key 与 Date.relativeTime 一致）。
private func formatRelative(_ count: Int, _ unit: String) -> String {
    let format = pluginLocalization.count("%lld \(unit) ago", "%lld \(unit)s ago", for: count)
    return String(format: format, Int64(count))
}

@Test func conversationPageCursorKeepsItsTimestampAndIdentifier() {
    let timestamp = Date(timeIntervalSince1970: 1234)
    let identifier = UUID()
    let cursor = ConversationPageCursor(lastMessageAt: timestamp, id: identifier)

    #expect(cursor.lastMessageAt == timestamp)
    #expect(cursor.id == identifier)
}
