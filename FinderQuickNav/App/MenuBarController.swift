import AppKit

@MainActor
final class MenuBarController {
    static let shared = MenuBarController()

    private var statusItem: NSStatusItem?

    private init() {}

    func install() {
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "house.fill",
                accessibilityDescription: "man导"
            )
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "打开“man导 设置”",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "退出 man导",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        item.menu = menu

        statusItem = item
        NSLog("FQN menu bar item installed")
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
