import Foundation

enum QuickNavTabPreference: String, Codable, CaseIterable, Sendable {
    case favorites
    case recents
}

struct QuickNavPreferences: Codable, Equatable, Sendable {
    var keepPanelOpenAfterNavigation: Bool = true
    var showFullPathOnHover: Bool = true
    var defaultTab: QuickNavTabPreference = .favorites
    var enabledQuickNavActions: Set<String> = ["previous", "up", "favorite"]
}

final class QuickNavPreferencesStore {
    static let sharedSuiteName = "group.local.finderquicknav"

    private let defaults: UserDefaults
    private let key = "FinderQuickNav.quickNavPreferences"

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: Self.sharedSuiteName)
            ?? .standard
    }

    var preferences: QuickNavPreferences {
        guard let data = defaults.data(forKey: key),
              let value = try? JSONDecoder().decode(QuickNavPreferences.self, from: data) else {
            return QuickNavPreferences()
        }
        return value
    }

    func update(_ value: QuickNavPreferences) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
