import Foundation
import LumiLocalizationKit

/// 插件作用域的本地化服务（绑定本模块资源 bundle）。
///
/// 由原 `LumiPluginLocalization` 转发 shim 收敛而来；调用点使用 `pluginLocalization.string(_:)`。
public let pluginLocalization = PluginLocalization(bundle: .module)

/// 英文单复数：count == 1 取 singular key，其余取 plural key。
/// 返回已解析的格式串；调用点继续用 `String(format:)` 填充 `%lld`/`%@` 占位符。
extension PluginLocalization {
    public func count(_ singular: String, _ plural: String, for count: Int) -> String {
        string(count == 1 ? singular : plural)
    }
}
