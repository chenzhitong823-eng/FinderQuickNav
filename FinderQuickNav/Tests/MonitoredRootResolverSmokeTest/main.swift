import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

let sandboxFallback = URL(
    fileURLWithPath: "/Users/example/Library/Containers/local.finderquicknav.app.extension/Data",
    isDirectory: true
)

let accountHome = MonitoredRootResolver.homeURL(
    accountHomePath: "/Users/example",
    environment: ["HOME": sandboxFallback.path],
    fallback: sandboxFallback
)
expect(accountHome.path == "/Users/example", "The account home should override sandbox HOME")

let missingHome = MonitoredRootResolver.homeURL(
    accountHomePath: nil,
    environment: [:],
    fallback: sandboxFallback
)
expect(missingHome == sandboxFallback, "Missing account home and HOME should use the fallback URL")

let relativeHome = MonitoredRootResolver.homeURL(
    accountHomePath: "Users/example",
    environment: ["HOME": "Users/example"],
    fallback: sandboxFallback
)
expect(relativeHome == sandboxFallback, "Relative home paths must not be accepted")

print("monitored root resolver smoke test passed")
