import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let suiteName = "local.finderquicknav.folder-stores-smoke"
let defaults = UserDefaults(suiteName: suiteName)!
defaults.removePersistentDomain(forName: suiteName)

let documents = URL(fileURLWithPath: "/Users/example/Documents", isDirectory: true)
let codex = URL(fileURLWithPath: "/Users/example/Documents/Codex", isDirectory: true)
let work = URL(fileURLWithPath: "/Users/example/Documents/work", isDirectory: true)

let favorites = FavoritesStore(defaults: defaults)
favorites.add(documents)
favorites.add(codex)
favorites.add(documents)
expect(favorites.entries.map(\.path) == [documents.path, codex.path], "Favorites should deduplicate while preserving order")

let persistedFavorites = FavoritesStore(defaults: defaults)
expect(persistedFavorites.entries == favorites.entries, "Favorites should persist across store instances")

persistedFavorites.remove(documents)
expect(persistedFavorites.entries.map(\.path) == [codex.path], "Favorites should remove one entry")

let recents = RecentsStore(defaults: defaults, maximumCount: 2)
recents.record(documents)
recents.record(codex)
recents.record(documents)
recents.record(work)
expect(recents.entries.map(\.path) == [work.path, documents.path], "Recents should move newest to front and enforce a limit")

print("folder stores smoke test passed")
