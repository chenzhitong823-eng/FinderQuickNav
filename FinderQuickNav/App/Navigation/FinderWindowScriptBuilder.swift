import Foundation

enum FinderWindowScriptBuilder {
    static func navigateScript(to directory: URL) -> String {
        let escapedPath = appleScriptStringLiteralContent(directory.standardizedFileURL.path)

        return """
        tell application "Finder"
            if (count of Finder windows) is 0 then error number -1719
            set target of front Finder window to (POSIX file "\(escapedPath)" as alias)
        end tell
        """
    }

    static func currentTargetScript() -> String {
        """
        tell application "Finder"
            if (count of Finder windows) is 0 then error number -1719
            return POSIX path of (target of front Finder window as alias)
        end tell
        """
    }

    static func revealScript(to file: URL) -> String {
        let escapedPath = appleScriptStringLiteralContent(file.standardizedFileURL.path)

        return """
        tell application "Finder"
            if (count of Finder windows) is 0 then error number -1719
            set newItem to (POSIX file "\(escapedPath)" as alias)
            reveal newItem
            select newItem
        end tell
        """
    }

    private static func appleScriptStringLiteralContent(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
