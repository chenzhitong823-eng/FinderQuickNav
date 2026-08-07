import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let target = URL(fileURLWithPath: "/Users/example/课程/John's \\资料", isDirectory: true)
let script = FinderWindowScriptBuilder.navigateScript(to: target)

expect(script.contains("tell application \"Finder\""), "Script must target Finder")
expect(script.contains("POSIX file"), "Script must use a POSIX file alias")
expect(script.contains("John's \\\\资料"), "Backslashes must be escaped")
expect(script.contains("课程"), "Unicode paths must be preserved")
expect(!script.contains("; do shell"), "Script must not contain shell interpolation")

let revealScript = FinderWindowScriptBuilder.revealScript(to: target)
expect(revealScript.contains("reveal newItem"), "Reveal script must reveal the created item")
expect(revealScript.contains("select newItem"), "Reveal script must select the created item")
expect(revealScript.contains("John's \\\\资料"), "Reveal script must escape backslashes")

print("finder window script smoke test passed")
