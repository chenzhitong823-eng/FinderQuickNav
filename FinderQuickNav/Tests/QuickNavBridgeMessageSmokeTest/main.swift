import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let expected = QuickNavBridgeMessage(
    action: .show,
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000123")!,
    directoryURL: URL(fileURLWithPath: "/Users/example/My Folder", isDirectory: true),
    mouseX: 585,
    mouseY: 317,
    timestamp: Date(timeIntervalSince1970: 123.5)
)

let encoded = try QuickNavBridgeCodec.encode(expected)
let decoded = try QuickNavBridgeCodec.decode(
    encoded,
    now: Date(timeIntervalSince1970: 123.5),
    fileManager: FileManagerProbe()
)

expect(decoded == expected, "Bridge message did not round-trip")
expect(encoded.contains("My%20Folder"), "Bridge payload should preserve the encoded path")

for action in [
    QuickNavAction.show,
    .createFolder,
    .createText,
    .createMarkdown,
    .createWord,
    .createExcel,
    .createPowerPoint
] {
    let actionMessage = QuickNavBridgeMessage(
        action: action,
        id: UUID(),
        directoryURL: expected.directoryURL,
        mouseX: expected.mouseX,
        mouseY: expected.mouseY,
        timestamp: expected.timestamp
    )
    let actionDecoded = try QuickNavBridgeCodec.decode(
        try QuickNavBridgeCodec.encode(actionMessage),
        now: expected.timestamp,
        fileManager: FileManagerProbe()
    )
    expect(actionDecoded.action == action, "Action did not round-trip: \(action.rawValue)")
}

print("quick nav bridge message smoke test passed")

final class FileManagerProbe: FileManager {
    override func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        isDirectory?.pointee = true
        return true
    }
}
