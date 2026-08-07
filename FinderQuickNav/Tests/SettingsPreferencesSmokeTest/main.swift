import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let suiteName = "local.finderquicknav.settings-preferences-smoke"
let defaults = UserDefaults(suiteName: suiteName)!
defaults.removePersistentDomain(forName: suiteName)

let preferences = QuickNavPreferencesStore(defaults: defaults)
expect(preferences.preferences.keepPanelOpenAfterNavigation, "panel should stay open by default")
expect(preferences.preferences.showFullPathOnHover, "full path hover should be enabled by default")

var updated = preferences.preferences
updated.keepPanelOpenAfterNavigation = false
preferences.update(updated)
expect(!QuickNavPreferencesStore(defaults: defaults).preferences.keepPanelOpenAfterNavigation, "preferences should persist")

let favorites = FavoritesStore(defaults: defaults)
let documents = URL(fileURLWithPath: "/Users/example/Documents", isDirectory: true)
let work = URL(fileURLWithPath: "/Users/example/work", isDirectory: true)
favorites.add(documents)
favorites.rename(path: documents.path, displayName: "课程资料")
favorites.add(work)
favorites.move(path: work.path, to: 0)
expect(favorites.entries.map(\.displayName) == ["work", "课程资料"], "favorites should rename and reorder")
favorites.setEnabled(path: work.path, false)
expect(!FavoritesStore(defaults: defaults).entries[0].isEnabled, "favorite enabled state should persist")

let newFiles = NewFilePreferencesStore(defaults: defaults)
expect(newFiles.entries.count == 6, "six new-file actions should be enabled by default")
newFiles.setEnabled(action: .createWord, false)
expect(!NewFilePreferencesStore(defaults: defaults).isEnabled(.createWord), "new-file enabled state should persist")

print("settings preferences smoke test passed")
