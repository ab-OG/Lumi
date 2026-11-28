import Foundation
import LumiLocalizationKit

/// 插件作用域的本地化服务（绑定本模块资源 bundle）。
public let pluginLocalization = PluginLocalization(bundle: .module)

extension PluginLocalization {
    /// 计数标签的单/复数 key 选择（与 PR #7 的 ProviderSettings 约定一致）。
    ///
    /// 返回已解析的格式串；调用点继续用 `String(format:)` 填充 `%lld` 占位符。
    public func count(_ singular: String, _ plural: String, for count: Int) -> String {
        string(count == 1 ? singular : plural)
    }
}
