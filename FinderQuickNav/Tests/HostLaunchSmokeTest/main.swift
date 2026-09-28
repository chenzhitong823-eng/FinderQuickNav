import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("host launch smoke test failed: \(message)\n", stderr)
        exit(1)
    }
}

let appexURL = URL(
    fileURLWithPath: "/Users/mac/Applications/FinderQuickNav.app/Contents/PlugIns/FinderQuickNavExtension.appex",
    isDirectory: true
)
let host = HostSessionEnsurer.hostURL(forExtensionBundle: appexURL)
expect(
    host?.path == "/Users/mac/Applications/FinderQuickNav.app",
    "host URL must be the enclosing .app bundle"
)

let nestedAppex = URL(
    fileURLWithPath: "/tmp/Outer.app/Contents/PlugIns/Inner.appex",
    isDirectory: true
)
expect(
    HostSessionEnsurer.hostURL(forExtensionBundle: nestedAppex)?.path == "/tmp/Outer.app",
    "host URL should work for a plain .app/.appex layout"
)

let orphanURL = URL(
    fileURLWithPath: "/tmp/NotInAnApp/Contents/PlugIns/Orphan.appex",
    isDirectory: true
)
expect(
    HostSessionEnsurer.hostURL(forExtensionBundle: orphanURL) == nil,
    "host URL must be nil when no enclosing .app exists"
)

let installedHostURL = URL(
    fileURLWithPath: "/Users/mac/Applications/FinderQuickNav.app",
    isDirectory: true
)
let staleArchivedHostURL = URL(
    fileURLWithPath: "/Users/mac/Documents/project/FinderQuickNav/system/archive/FinderQuickNav-before-bridge.app",
    isDirectory: true
)
expect(
    !HostSessionEnsurer.isExpectedHostRunning(
        installedHostURL,
        among: [staleArchivedHostURL]
    ),
    "an archived app with the same bundle ID must not suppress the installed host launch"
)
expect(
    HostSessionEnsurer.isExpectedHostRunning(
        installedHostURL,
        among: [installedHostURL]
    ),
    "the enclosing installed app must be recognized as the running host"
)

print("host launch smoke test passed")
