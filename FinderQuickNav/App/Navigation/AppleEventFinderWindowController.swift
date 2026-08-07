import AppKit
import CoreGraphics

final class AppleEventFinderWindowController: FinderWindowControlling {
    private static let finderBundleIdentifier = "com.apple.finder"
    private static let backKeyCode: CGKeyCode = 33
    private static let upKeyCode: CGKeyCode = 126

    var isFinderFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Self.finderBundleIdentifier
    }

    func activateFinder() -> Bool {
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.finderBundleIdentifier
        ).first else {
            return false
        }

        return finder.activate(options: [])
    }

    func sendBackShortcut() throws {
        try sendCommandKey(Self.backKeyCode)
    }

    func sendUpShortcut() throws {
        try sendCommandKey(Self.upKeyCode)
    }

    func setFrontWindowTarget(_ directory: URL) throws {
        let script = FinderWindowScriptBuilder.navigateScript(to: directory)
        _ = try execute(script)
    }

    func currentTarget() throws -> URL {
        let result = try execute(FinderWindowScriptBuilder.currentTargetScript())
        guard let path = result.stringValue, !path.isEmpty else {
            throw FinderNavigationError.operationFailed(-1708)
        }
        return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
    }

    func reveal(_ file: URL) throws {
        _ = try execute(FinderWindowScriptBuilder.revealScript(to: file))
    }

    private func sendCommandKey(_ keyCode: CGKeyCode) throws {
        guard FinderPermissionCenter.accessibilityIsGranted() else {
            throw FinderNavigationError.accessibilityDenied
        }

        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: keyCode,
                  keyDown: true
              ),
              let keyUp = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: keyCode,
                  keyDown: false
              ) else {
            throw FinderNavigationError.operationFailed(-1)
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func execute(_ source: String) throws -> NSAppleEventDescriptor {
        guard let script = NSAppleScript(source: source) else {
            throw FinderNavigationError.operationFailed(-1708)
        }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            let status = (error[NSAppleScript.errorNumber] as? NSNumber)?.intValue ?? -1708
            throw FinderAutomationErrorMapper.navigationError(for: status)
        }
        return result
    }
}
