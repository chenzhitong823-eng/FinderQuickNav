import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

final class RecordingFinderWindowController: FinderWindowControlling {
    var isFinderFrontmost: Bool
    var activationSucceeds = false
    var activationCount = 0
    var backShortcutCount = 0
    var upShortcutCount = 0
    var targetPaths: [String] = []
    var currentTargetURL: URL?

    init(isFinderFrontmost: Bool) {
        self.isFinderFrontmost = isFinderFrontmost
    }

    func activateFinder() -> Bool {
        activationCount += 1
        if activationSucceeds {
            isFinderFrontmost = true
        }
        return activationSucceeds
    }

    func sendBackShortcut() throws {
        backShortcutCount += 1
    }

    func sendUpShortcut() throws {
        upShortcutCount += 1
    }

    func setFrontWindowTarget(_ directory: URL) throws {
        targetPaths.append(directory.path)
    }

    func currentTarget() throws -> URL {
        currentTargetURL ?? URL(fileURLWithPath: "/Users/example/Documents", isDirectory: true)
    }
}

func expectError(
    _ operation: () throws -> Void,
    _ expected: FinderNavigationError,
    _ message: String
) {
    do {
        try operation()
        fatalError("Expected (expected): (message)")
    } catch let error as FinderNavigationError {
        guard error == expected else {
            fatalError("Expected (expected), got (error): (message)")
        }
    } catch {
        fatalError("Unexpected error (error): (message)")
    }
}

let inactiveController = RecordingFinderWindowController(isFinderFrontmost: false)
let inactiveNavigator = FinderNavigator(controller: inactiveController)
expectError(
    { try inactiveNavigator.goBack() },
    .finderNotFrontmost,
    "back must reject a non-frontmost Finder"
)
if inactiveController.backShortcutCount != 0 {
    fatalError("back shortcut was sent while Finder was not frontmost")
}

let activationController = RecordingFinderWindowController(isFinderFrontmost: false)
activationController.activationSucceeds = true
let activationNavigator = FinderNavigator(controller: activationController)
try activationNavigator.goBack()
if activationController.activationCount != 1 || activationController.backShortcutCount != 1 {
    fatalError("Finder should be activated before sending a back shortcut")
}

let rootController = RecordingFinderWindowController(isFinderFrontmost: true)
let rootNavigator = FinderNavigator(controller: rootController)
expectError(
    { try rootNavigator.goUp(from: URL(fileURLWithPath: "/", isDirectory: true)) },
    .invalidDirectory,
    "root must not navigate to a parent"
)
if rootController.upShortcutCount != 0 {
    fatalError("up shortcut was sent for the root directory")
}

let invalidController = RecordingFinderWindowController(isFinderFrontmost: true)
let invalidNavigator = FinderNavigator(controller: invalidController)
expectError(
    { try invalidNavigator.navigate(to: URL(fileURLWithPath: "/definitely/not/a/real/folder", isDirectory: true)) },
    .invalidDirectory,
    "invalid directory must be rejected"
)
if !invalidController.targetPaths.isEmpty {
    fatalError("Apple Event target was sent for an invalid directory")
}

let validController = RecordingFinderWindowController(isFinderFrontmost: true)
let validNavigator = FinderNavigator(controller: validController)
let validDirectory = FileManager.default.temporaryDirectory
try validNavigator.navigate(to: validDirectory)
if validController.targetPaths != [validDirectory.standardizedFileURL.path] {
    fatalError("Valid directory target was not sent exactly once")
}

let sessionDirectory = URL(fileURLWithPath: "/Users/example/Documents", isDirectory: true)
let nextDirectory = URL(fileURLWithPath: "/Users/example/Documents/Codex", isDirectory: true)
var session = QuickNavSessionState()
session.present(directory: sessionDirectory)
expect(session.isPresented, "present should keep the session visible")
session.selectTab(.recents)
expect(session.selectedTab == .recents, "session should remember the recent-visits tab")
session.didNavigate(to: nextDirectory)
expect(session.isPresented, "navigation should not dismiss the session")
expect(session.currentDirectory == nextDirectory.standardizedFileURL, "navigation should refresh the current directory")
expect(session.selectedTab == .recents, "navigation should preserve the recent-visits tab")

var favoritesSession = QuickNavSessionState()
favoritesSession.present(directory: sessionDirectory, defaultTab: .favorites)
favoritesSession.selectTab(.favorites)
favoritesSession.didNavigate(to: nextDirectory)
expect(favoritesSession.selectedTab == .favorites, "navigation should preserve the favorites tab")

session.dismiss()
expect(!session.isPresented, "explicit dismiss should close the session")

print("finder navigation policy smoke test passed")
