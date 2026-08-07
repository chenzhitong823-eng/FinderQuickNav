import Foundation

let storeSuite = "test-pending-fqn-\(UUID().uuidString)"
defer {
    UserDefaults(suiteName: storeSuite)?.removePersistentDomain(forName: storeSuite)
}

func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("pending quick-nav request store smoke test failed: \(message)\n", stderr)
        exit(1)
    }
}

let directory = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString, isDirectory: true)
try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
defer {
    try? FileManager.default.removeItem(at: directory)
}

let message = QuickNavBridgeMessage(
    action: .show,
    id: UUID(),
    directoryURL: directory,
    mouseX: 100,
    mouseY: 200,
    timestamp: Date()
)

try PendingQuickNavRequestStore.save(message, suiteName: storeSuite)
assert(
    PendingQuickNavRequestStore.takePending(suiteName: storeSuite) == message,
    "saved request must round-trip"
)
assert(
    PendingQuickNavRequestStore.takePending(suiteName: storeSuite) == nil,
    "request must be consumed exactly once"
)

let staleMessage = QuickNavBridgeMessage(
    action: .show,
    id: UUID(),
    directoryURL: directory,
    mouseX: 1,
    mouseY: 2,
    timestamp: Date().addingTimeInterval(-60)
)
try PendingQuickNavRequestStore.save(staleMessage, suiteName: storeSuite)
assert(
    PendingQuickNavRequestStore.takePending(suiteName: storeSuite) == nil,
    "stale request must be dropped and cleared"
)

let invalidDirectoryMessage = QuickNavBridgeMessage(
    action: .show,
    id: UUID(),
    directoryURL: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)"),
    mouseX: 3,
    mouseY: 4,
    timestamp: Date()
)
try PendingQuickNavRequestStore.save(invalidDirectoryMessage, suiteName: storeSuite)
assert(
    PendingQuickNavRequestStore.takePending(suiteName: storeSuite) == nil,
    "invalid-directory request must be dropped and cleared"
)

print("pending quick-nav request store smoke test passed")
