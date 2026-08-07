import AppKit
import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("path copy smoke test failed: \(message)\n", stderr)
        exit(1)
    }
}

let pasteboard = NSPasteboard(
    name: NSPasteboard.Name("test-path-copy-\(UUID().uuidString)")
)
let path = "/Users/mac/Documents/Codex"

let result = QuickNavPathCopyService.copy(path, pasteboard: pasteboard)
expect(result == path, "copy should return the copied path")
expect(
    pasteboard.string(forType: .string) == path,
    "pasteboard should contain the current folder path"
)

let secondPath = "/Users/mac/Documents/Codex/课堂"
let secondResult = QuickNavPathCopyService.copy(secondPath, pasteboard: pasteboard)
expect(secondResult == secondPath, "a later copy should return the new path")
expect(
    pasteboard.string(forType: .string) == secondPath,
    "a later copy should replace the previous pasteboard value"
)

print("path copy smoke test passed")
