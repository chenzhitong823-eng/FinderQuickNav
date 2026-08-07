import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var requestDeduplicator = QuickNavRequestDeduplicator()
    private let requestDeduplicatorLock = NSLock()
    private let newFileService = NewFileService()
    private let finderController = AppleEventFinderWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        MenuBarController.shared.install()

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleQuickNavBridgeMessage(_:)),
            name: QuickNavDistributedBridge.notificationName,
            object: nil
        )

        // A pending Finder request means the extension woke us up: show only
        // the quick-nav panel. Without one (Launchpad or Finder double-click),
        // show the settings window. The preference read runs off the main
        // thread so a slow preference domain can never delay the window.
        Task { @MainActor in
            await self.drainOrShowSettings()
        }

        // cfprefsd may propagate the extension's write a moment after launch,
        // and a second Finder click can arrive while the host is still starting.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            await self.drainPendingQuickNavRequestOffMain()
        }
        NSLog("FQN host launched")
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        SettingsWindowController.shared.show()
        return true
    }

    @objc private func handleQuickNavBridgeMessage(_ notification: Notification) {
        guard let payload = notification.object as? String else {
            NSLog("FQN bridge rejected non-string payload")
            return
        }

        PendingQuickNavRequestStore.clear()

        do {
            let message = try QuickNavBridgeCodec.decode(payload)
            NSLog(
                "FQN bridge received id=%@ path=%@ mouse={%f, %f} ts=%f",
                message.id.uuidString,
                message.directoryPath,
                message.mouseX,
                message.mouseY,
                message.timestamp.timeIntervalSince1970
            )
            guard acceptRequestID(message.id) else {
                NSLog("FQN bridge rejected duplicate id=%@", message.id.uuidString)
                return
            }
            Task { @MainActor in
                self.handle(message)
            }
        } catch let error as QuickNavRequestError {
            NSLog("FQN bridge request rejected=%@", String(describing: error))
        } catch {
            NSLog("FQN bridge decode failed=%@", error.localizedDescription)
        }
    }

    private func drainPendingQuickNavRequest() {
        guard let message = PendingQuickNavRequestStore.takePending() else { return }
        handlePending(message)
    }

    @MainActor
    private func drainOrShowSettings() async {
        if let pendingRequest = await takePendingOffMain() {
            handlePending(pendingRequest)
        } else {
            SettingsWindowController.shared.show()
        }
    }

    @MainActor
    private func drainPendingQuickNavRequestOffMain() async {
        guard let pendingRequest = await takePendingOffMain() else { return }
        handlePending(pendingRequest)
    }

    private func takePendingOffMain() async -> QuickNavBridgeMessage? {
        await Task.detached(priority: .userInitiated) {
            PendingQuickNavRequestStore.takePending()
        }.value
    }

    private func handlePending(_ message: QuickNavBridgeMessage) {
        NSLog(
            "FQN bridge drained pending id=%@ path=%@",
            message.id.uuidString,
            message.directoryPath
        )
        guard acceptRequestID(message.id) else {
            NSLog("FQN bridge rejected duplicate id=%@", message.id.uuidString)
            return
        }
        Task { @MainActor in
            self.handle(message)
        }
    }

    private func acceptRequestID(_ id: UUID) -> Bool {
        requestDeduplicatorLock.lock()
        defer { requestDeduplicatorLock.unlock() }
        return requestDeduplicator.accept(id)
    }

    @MainActor
    private func handle(_ message: QuickNavBridgeMessage) {
        switch message.action {
        case .show:
            QuickNavPanelController.shared.show(message: message)
        case .createFolder, .createText, .createMarkdown, .createWord, .createExcel, .createPowerPoint:
            createNewFile(for: message)
        }
    }

    @MainActor
    private func createNewFile(for message: QuickNavBridgeMessage) {
        guard let kind = newFileKind(for: message.action) else { return }
        QuickNavPanelController.shared.dismiss()

        do {
            let created = try newFileService.create(kind: kind, in: message.directoryURL)
            NSLog(
                "FQN new-file result=created kind=%@ path=%@",
                kind.menuTitle,
                created.path
            )

            do {
                try revealInFinder(created)
            } catch {
                NSLog(
                    "FQN new-file reveal failed path=%@ error=%@",
                    created.path,
                    String(describing: error)
                )
                presentNewFileError(
                    title: "文件已创建，但 Finder 未能选中",
                    directory: message.directoryURL,
                    detail: String(describing: error)
                )
            }
        } catch {
            NSLog(
                "FQN new-file result=error kind=%@ directory=%@ error=%@",
                kind.menuTitle,
                message.directoryPath,
                String(describing: error)
            )
            presentNewFileError(
                title: "新建文件失败",
                directory: message.directoryURL,
                detail: String(describing: error)
            )
        }
    }

    private func newFileKind(for action: QuickNavAction) -> NewFileKind? {
        switch action {
        case .show:
            return nil
        case .createFolder:
            return .folder
        case .createText:
            return .text
        case .createMarkdown:
            return .markdown
        case .createWord:
            return .word
        case .createExcel:
            return .excel
        case .createPowerPoint:
            return .powerPoint
        }
    }

    private func revealInFinder(_ file: URL) throws {
        guard finderController.isFinderFrontmost
                || (finderController.activateFinder() && finderController.isFinderFrontmost) else {
            throw FinderNavigationError.finderNotFrontmost
        }
        try finderController.reveal(file)
    }

    @MainActor
    private func presentNewFileError(title: String, directory: URL, detail: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.informativeText = "目录：\(directory.path)\n\(detail)"
        alert.addButton(withTitle: "知道了")
        alert.runModal()
    }
}
