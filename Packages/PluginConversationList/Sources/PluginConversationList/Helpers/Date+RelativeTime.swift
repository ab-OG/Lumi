import Foundation

public extension Date {
    /// 返回相对于当前时间的描述
    /// - Returns: 如 "Just now", "5m ago", "2h ago", "3d ago"
    var relativeTime: String {
        let delta = Date().timeIntervalSince(self)
        guard delta >= 0 else { return pluginLocalization.string("Just now") }

        let minutes = Int(delta) / 60
        if minutes < 60 {
            guard minutes >= 1 else { return pluginLocalization.string("Just now") }
            let format = pluginLocalization.count("%lld minute ago", "%lld minutes ago", for: minutes)
            return String(format: format, Int64(minutes))
        }

        let hours = minutes / 60
        if hours < 24 {
            let format = pluginLocalization.count("%lld hour ago", "%lld hours ago", for: hours)
            return String(format: format, Int64(hours))
        }

        let days = hours / 24
        let format = pluginLocalization.count("%lld day ago", "%lld days ago", for: days)
        return String(format: format, Int64(days))
    }
}
