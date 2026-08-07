import Foundation

enum SettingsSection: String, CaseIterable, Hashable, Identifiable, Sendable {
    case quickNavigation
    case favorites
    case newFiles
    case permissions

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickNavigation: return "快速导航"
        case .favorites: return "个人收藏"
        case .newFiles: return "新建文件"
        case .permissions: return "权限与扩展"
        }
    }

    var subtitle: String {
        switch self {
        case .quickNavigation: return "卡片行为与路径显示"
        case .favorites: return "目录、名称与排序"
        case .newFiles: return "右键菜单入口"
        case .permissions: return "Finder 与系统权限"
        }
    }

    var symbolName: String {
        switch self {
        case .quickNavigation: return "sparkles"
        case .favorites: return "star"
        case .newFiles: return "doc.badge.plus"
        case .permissions: return "lock.shield"
        }
    }

    static func route(for footerTitle: String) -> SettingsSection? {
        footerTitle == "管理收藏…" ? .favorites : nil
    }
}
