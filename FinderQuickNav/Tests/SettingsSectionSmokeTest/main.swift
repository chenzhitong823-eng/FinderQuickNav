import Foundation

func expectSection(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

expectSection(
    SettingsSection.allCases == [.quickNavigation, .favorites, .newFiles, .permissions],
    "settings should expose the four approved modules in order"
)
expectSection(
    SettingsSection.route(for: "管理收藏…") == .favorites,
    "manage favorites should route to the favorites module"
)
expectSection(
    !SettingsSection.allCases.contains(where: { $0.title == "发送到" }),
    "send-to should not be an active settings module yet"
)

print("settings section smoke test passed")
