import Foundation
import CoreGraphics

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let directory = URL(fileURLWithPath: "/Users/example/My Folder", isDirectory: true)
let mouse = CGPoint(x: 585, y: 317)
let timestamp = Date(timeIntervalSince1970: 123.5)

guard let url = ExtensionRequestURLBuilder.showURL(
    directoryURL: directory,
    mouseLocation: mouse,
    timestamp: timestamp
) else {
    fatalError("Expected a valid custom URL")
}

expect(url.scheme == "finderquicknav", "Unexpected URL scheme")
expect(url.host == "show", "Unexpected URL host")

let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
let query = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })

expect(query["path"] == "/Users/example/My Folder", "Directory path did not round-trip")
expect(query["x"] == "585.0", "Mouse x coordinate did not round-trip")
expect(query["y"] == "317.0", "Mouse y coordinate did not round-trip")
expect(query["ts"] == "123.5", "Timestamp did not round-trip")

print("extension request URL builder smoke test passed")
