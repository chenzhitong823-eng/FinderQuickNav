import AppKit
import Combine
import SwiftUI

@MainActor
final class SettingsWindowModel: ObservableObject {
    @Published var selectedSection: SettingsSection

    init(selectedSection: SettingsSection = .quickNavigation) {
        self.selectedSection = selectedSection
    }
}

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    let model = SettingsWindowModel()
    private var window: NSWindow?

    private override init() {}

    func show(section: SettingsSection = .quickNavigation) {
        model.selectedSection = section

        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(rootView: SettingsView(model: model))
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 780, height: 520),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "man导 设置"
        window.contentView = hostingView
        window.minSize = CGSize(width: 700, height: 460)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setFrameAutosaveName("FinderQuickNav.SettingsWindow")
        window.center()
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
