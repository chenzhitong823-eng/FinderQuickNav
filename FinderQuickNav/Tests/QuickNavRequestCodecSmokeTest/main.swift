import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

func expectError(
    _ operation: () throws -> Void,
    _ expected: QuickNavRequestError,
    _ message: String
) {
    do {
        try operation()
        fatalError("Expected (expected): (message)")
    } catch let error as QuickNavRequestError {
        guard error == expected else {
            fatalError("Expected (expected), got (error): (message)")
        }
    } catch {
        fatalError("Unexpected error (error): (message)")
    }
}

let directory = FileManager.default.temporaryDirectory.standardizedFileURL
let requestDate = Date(timeIntervalSince1970: 100)
let request = QuickNavBridgeMessage(
    action: .show,
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000321")!,
    directoryURL: directory,
    mouseX: 585,
    mouseY: 317,
    timestamp: requestDate
)

let encoded = try QuickNavBridgeCodec.encode(request)
let decoded = try QuickNavBridgeCodec.decode(encoded, now: Date(timeIntervalSince1970: 103))
expect(decoded == request, "A fresh request should round-trip")

expectError(
    { _ = try QuickNavBridgeCodec.decode(encoded, now: Date(timeIntervalSince1970: 106)) },
    .expired,
    "Expired requests must be rejected"
)

let remoteURL = URL(string: "https://example.com/Documents")!
let remoteRequest = QuickNavBridgeMessage(
    action: .show,
    id: UUID(),
    directoryURL: remoteURL,
    mouseX: 1,
    mouseY: 2,
    timestamp: requestDate
)
expectError(
    { _ = try QuickNavBridgeCodec.decode(try QuickNavBridgeCodec.encode(remoteRequest), now: Date(timeIntervalSince1970: 101)) },
    .nonFileURL,
    "Remote URLs must be rejected"
)

let missingDirectory = URL(fileURLWithPath: "/definitely/not/a/real/folder", isDirectory: true)
let missingRequest = QuickNavBridgeMessage(
    action: .show,
    id: UUID(),
    directoryURL: missingDirectory,
    mouseX: 1,
    mouseY: 2,
    timestamp: requestDate
)
expectError(
    { _ = try QuickNavBridgeCodec.decode(try QuickNavBridgeCodec.encode(missingRequest), now: Date(timeIntervalSince1970: 101)) },
    .notDirectory,
    "Missing directories must be rejected"
)

let unknownAction = encoded.replacingOccurrences(of: "show", with: "erase")
expectError(
    { _ = try QuickNavBridgeCodec.decode(unknownAction, now: Date(timeIntervalSince1970: 101)) },
    .unsupportedAction,
    "Unknown actions must be rejected"
)

var deduplicator = QuickNavRequestDeduplicator()
expect(deduplicator.accept(request.id), "First request ID should be accepted")
expect(!deduplicator.accept(request.id), "Second request ID should be rejected")

// The bridge and the pending store may deliver the same new-file action.
// After the cache fills, every recent request must still execute only once.
let requestIDs = (0..<512).map { _ in UUID() }
var rollingDeduplicator = QuickNavRequestDeduplicator()
for (index, id) in requestIDs.enumerated() {
    expect(rollingDeduplicator.accept(id), "A new request should be accepted")
    let recentStart = max(0, index - 127)
    for recentID in requestIDs[recentStart...index] {
        expect(
            !rollingDeduplicator.accept(recentID),
            "A duplicate among the latest 128 requests must never be replayed"
        )
    }
}
expect(
    rollingDeduplicator.accept(requestIDs[0]),
    "Old IDs must eventually be evicted so memory remains bounded"
)

print("quick nav request codec smoke test passed")
