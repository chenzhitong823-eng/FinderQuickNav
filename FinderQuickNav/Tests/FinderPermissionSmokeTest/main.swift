import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

expect(
    FinderAutomationErrorMapper.navigationError(for: -1743) == .automationDenied,
    "Apple Event permission denial must be mapped explicitly"
)
expect(
    FinderAutomationErrorMapper.navigationError(for: -1719) == .noFinderWindow,
    "Missing Finder window must remain distinguishable"
)
expect(
    FinderAutomationErrorMapper.navigationError(for: -1708) == .operationFailed(-1708),
    "Unexpected Apple Event errors must retain their status"
)

print("Finder permission mapping smoke test passed")
