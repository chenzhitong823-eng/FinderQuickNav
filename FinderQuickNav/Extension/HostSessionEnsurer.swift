import Cocoa

enum HostSessionEnsurer {
    static func hostURL(forExtensionBundle extensionURL: URL) -> URL? {
        var candidate = extensionURL.deletingLastPathComponent()
        for _ in 0..<5 {
            if candidate.pathExtension == "app" {
                return candidate
            }
            candidate = candidate.deletingLastPathComponent()
        }
        return nil
    }

    static func ensureRunning() {
        let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: QuickNavHostLaunch.bundleIdentifier
        )
        guard running.isEmpty else { return }

        // Extension bundle:
        //   .../FinderQuickNav.app/Contents/PlugIns/FinderQuickNavExtension.appex
        guard let hostURL = hostURL(forExtensionBundle: Bundle.main.bundleURL) else {
            NSLog(
                "FQN host launch aborted invalidHostURL=%@",
                Bundle.main.bundleURL.path
            )
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(
            at: hostURL,
            configuration: configuration
        ) { application, error in
            if let error {
                NSLog("FQN host launch failed error=%@", error.localizedDescription)
            } else if let application {
                NSLog("FQN host launched pid=%d", application.processIdentifier)
            }
        }
    }
}
