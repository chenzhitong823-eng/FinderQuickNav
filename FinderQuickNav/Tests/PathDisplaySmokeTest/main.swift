import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let directory = URL(fileURLWithPath: "/Users/mac/Documents/Codex", isDirectory: true)
let display = FolderPathDisplay(url: directory)
expect(display.compactLabel == "Codex", "compact path should use the current folder name")
expect(display.fullPath == "/Users/mac/Documents/Codex", "full path should preserve the root path")
expect(display.components.map(\.url.path) == ["/", "/Users", "/Users/mac", "/Users/mac/Documents", "/Users/mac/Documents/Codex"], "path components should be ordered from root")

let root = FolderPathDisplay(url: URL(fileURLWithPath: "/", isDirectory: true))
expect(root.compactLabel == "/", "root path should have a visible compact label")
expect(root.components.count == 1 && root.components[0].url.path == "/", "root should have one component")

print("path display smoke test passed")
