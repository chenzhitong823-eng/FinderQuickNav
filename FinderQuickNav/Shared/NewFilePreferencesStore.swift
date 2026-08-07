import Foundation

struct NewFileMenuEntry: Codable, Equatable, Identifiable, Sendable {
    let action: QuickNavAction
    var isEnabled: Bool

    var id: String { action.rawValue }

    var title: String {
        switch action {
        case .createFolder: return "文件夹"
        case .createText: return "TXT"
        case .createMarkdown: return "Markdown"
        case .createWord: return "Word"
        case .createExcel: return "Excel"
        case .createPowerPoint: return "PowerPoint"
        case .show: return "快速导航"
        }
    }
}

final class NewFilePreferencesStore {
    static let sharedSuiteName = "group.local.finderquicknav"

    private let defaults: UserDefaults
    private let key = "FinderQuickNav.newFilePreferences"

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: Self.sharedSuiteName)
            ?? .standard
    }

    var entries: [NewFileMenuEntry] {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode([NewFileMenuEntry].self, from: data),
              value.allSatisfy({ $0.action != .show }) else {
            return Self.defaultEntries
        }
        return value
    }

    var enabledEntries: [NewFileMenuEntry] {
        entries.filter(\.isEnabled)
    }

    func isEnabled(_ action: QuickNavAction) -> Bool {
        entries.first(where: { $0.action == action })?.isEnabled ?? false
    }

    func setEnabled(action: QuickNavAction, _ enabled: Bool) {
        guard action != .show else { return }
        var updated = entries
        guard let index = updated.firstIndex(where: { $0.action == action }) else { return }
        updated[index].isEnabled = enabled
        save(updated)
    }

    func move(action: QuickNavAction, to destination: Int) {
        var updated = entries
        guard let source = updated.firstIndex(where: { $0.action == action }) else { return }
        let entry = updated.remove(at: source)
        let index = min(max(0, destination), updated.count)
        updated.insert(entry, at: index)
        save(updated)
    }

    private func save(_ value: [NewFileMenuEntry]) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static let defaultEntries: [NewFileMenuEntry] = [
        .init(action: .createFolder, isEnabled: true),
        .init(action: .createText, isEnabled: true),
        .init(action: .createMarkdown, isEnabled: true),
        .init(action: .createWord, isEnabled: true),
        .init(action: .createExcel, isEnabled: true),
        .init(action: .createPowerPoint, isEnabled: true)
    ]
}
