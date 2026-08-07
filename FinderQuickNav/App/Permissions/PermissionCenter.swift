import ApplicationServices

enum FinderPermissionCenter {
    static func accessibilityIsGranted() -> Bool {
        AXIsProcessTrusted()
    }
}

enum FinderAutomationErrorMapper {
    static func navigationError(for status: Int) -> FinderNavigationError {
        switch status {
        case -1743:
            return .automationDenied
        case -1719:
            return .noFinderWindow
        default:
            return .operationFailed(status)
        }
    }
}
