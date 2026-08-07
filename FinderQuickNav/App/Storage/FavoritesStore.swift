import Foundation

final class FavoritesStore {
    private let defaults: UserDefaults
    private let key = "FinderQuickNav.favorites"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var entries: [FolderEntry] {
        guard let data = defaults.data(forKey: key),
              let entries = try? JSONDecoder().decode([FolderEntry].self, from: data) else {
            return []
        }
        return entries
    }

    func add(_ url: URL) {
        guard let entry = FolderEntry(url: url) else { return }
        var updated = entries
        guard !updated.contains(where: { $0.path == entry.path }) else { return }
        updated.append(entry)
        save(updated)
    }

    func remove(_ url: URL) {
        guard let entry = FolderEntry(url: url) else { return }
        save(entries.filter { $0.path != entry.path })
    }

    func rename(path: String, displayName: String) {
        var updated = entries
        guard let index = updated.firstIndex(where: { $0.path == path }) else { return }
        let cleaned = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        updated[index].displayName = cleaned
        save(updated)
    }

    func setEnabled(path: String, _ enabled: Bool) {
        var updated = entries
        guard let index = updated.firstIndex(where: { $0.path == path }) else { return }
        updated[index].isEnabled = enabled
        save(updated)
    }

    func move(path: String, to destination: Int) {
        var updated = entries
        guard let source = updated.firstIndex(where: { $0.path == path }) else { return }
        let entry = updated.remove(at: source)
        let index = min(max(0, destination), updated.count)
        updated.insert(entry, at: index)
        save(updated)
    }

    private func save(_ entries: [FolderEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}
