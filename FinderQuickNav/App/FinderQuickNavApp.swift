import SwiftUI

@main
struct FinderQuickNavApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(model: SettingsWindowController.shared.model)
        }
    }
}
