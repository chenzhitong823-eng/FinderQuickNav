import Foundation

final class RecentsStore {
    private let defaults: UserDefaults
    private let key = "FinderQuickNav.recents"
    private let maximumCount: Int

    init(defaults: UserDefaults = .standard, maximumCount: Int = 8) {
        self.defaults = defaults
        self.maximumCount = max(1, maximumCount)
    }

    var entries: [FolderEntry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([FolderEntry].self, from: data) else {
            return []
        }
        return entries
    }

    func record(_ url: URL) {
        guard let entry = FolderEntry(url: url) else { return }
        var updated = entries.filter { $0 != entry }
        updated.insert(entry, at: 0)
        save(Array(updated.prefix(maximumCount)))
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func save(_ entries: [FolderEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}
