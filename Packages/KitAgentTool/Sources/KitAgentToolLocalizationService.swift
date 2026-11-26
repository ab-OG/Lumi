import Foundation
import LumiLocalizationKit

/// 插件作用域的本地化服务（绑定本模块资源 bundle）。
///
/// 风险等级与授权状态等共享标签经此解析；调用点使用 `pluginLocalization.string(_:)`。
public let pluginLocalization = PluginLocalization(bundle: .module)
