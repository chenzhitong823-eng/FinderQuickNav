import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    private var enabledNewFileMenuItems: [(title: String, action: QuickNavAction)] {
        NewFilePreferencesStore().enabledEntries.map { ($0.title, $0.action) }
    }

    override init() {
        super.init()
        let monitoredHome = MonitoredRootResolver.homeURL()
        FIFinderSyncController.default().directoryURLs = [monitoredHome]
        NSLog(
            "FQN extension init monitoredHome=%@ accountHome=%@ nsHome=%@ environmentHome=%@",
            monitoredHome.path,
            MonitoredRootResolver.accountHomePath() ?? "<missing>",
            NSHomeDirectory(),
            ProcessInfo.processInfo.environment["HOME"] ?? "<missing>"
        )
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer else { return nil }
        let menu = NSMenu(title: "FinderQuickNav")
        let item = NSMenuItem(title: "快速导航", action: #selector(showQuickNav), keyEquivalent: "")
        item.target = self
        menu.addItem(item)

        let newFileMenuItems = enabledNewFileMenuItems
        if !newFileMenuItems.isEmpty {
            let newFileItem = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
            let newFileMenu = NSMenu(title: "新建文件")
            for (index, menuItem) in newFileMenuItems.enumerated() {
                let child = NSMenuItem(
                    title: menuItem.title,
                    action: #selector(createNewFile(_:)),
                    keyEquivalent: ""
                )
                child.target = self
                child.tag = index
                newFileMenu.addItem(child)
            }
            newFileItem.submenu = newFileMenu
            menu.addItem(newFileItem)
        }
        return menu
    }

    @objc private func showQuickNav() {
        post(action: .show)
    }

    @objc private func createNewFile(_ sender: NSMenuItem) {
        let newFileMenuItems = enabledNewFileMenuItems
        guard newFileMenuItems.indices.contains(sender.tag) else {
            NSLog("FQN new-file rejected invalid menu tag=%ld", sender.tag)
            return
        }
        post(action: newFileMenuItems[sender.tag].action)
    }

    private func post(action: QuickNavAction) {
        guard let target = FIFinderSyncController.default().targetedURL() else { return }
        let mouseLocation = NSEvent.mouseLocation
        NSLog(
            "FQN target=%@ action=%@ mouse=%@",
            target.path,
            action.rawValue,
            NSStringFromPoint(mouseLocation)
        )

        let message = QuickNavBridgeMessage(
            action: action,
            id: UUID(),
            directoryURL: target,
            mouseX: Double(mouseLocation.x),
            mouseY: Double(mouseLocation.y),
            timestamp: Date()
        )

        do {
            try PendingQuickNavRequestStore.save(message)
            HostSessionEnsurer.ensureRunning()
            try QuickNavDistributedBridge.post(message)
            NSLog(
                "FQN bridge dispatched id=%@ path=%@",
                message.id.uuidString,
                message.directoryPath
            )
        } catch {
            NSLog("FQN bridge send failed=%@", error.localizedDescription)
        }
    }
}
