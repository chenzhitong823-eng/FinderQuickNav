import AppKit
import SwiftUI

private final class QuickNavPanel: NSPanel {
    var onCancelOperation: (() -> Void)?

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onCancelOperation?()
    }
}

@MainActor
final class QuickNavPanelController {
    static let shared = QuickNavPanelController()

    private let panelSize = CGSize(width: 292, height: 286)
    private let finderController: AppleEventFinderWindowController
    private let navigator: FinderNavigator
    private let favoritesStore = FavoritesStore()
    private let recentsStore = RecentsStore()
    private let preferencesStore = QuickNavPreferencesStore()
    private lazy var panel: NSPanel = makePanel()
    private var currentMessage: QuickNavBridgeMessage?
    private var sessionState = QuickNavSessionState()
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var workspaceObserver: NSObjectProtocol?

    private init() {
        let finderController = AppleEventFinderWindowController()
        self.finderController = finderController
        self.navigator = FinderNavigator(controller: finderController)
    }

    func show(message: QuickNavBridgeMessage) {
        currentMessage = message
        recentsStore.record(message.directoryURL)
        let preferences = preferencesStore.preferences
        sessionState.present(
            directory: message.directoryURL,
            defaultTab: preferences.defaultTab
        )
        let before = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "<none>"
        let mouseLocation = CGPoint(x: message.mouseX, y: message.mouseY)
        let visibleFrame = screen(containing: mouseLocation)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(origin: .zero, size: panelSize)

        render(message: message)
        panel.setFrame(
            PanelPlacementEngine.frame(
                panelSize: panelSize,
                mouseLocation: mouseLocation,
                visibleFrame: visibleFrame
            ),
            display: true
        )
        panel.orderFrontRegardless()
        installEventMonitors()

        NSLog(
            "FQN panel shown id=%@ frontmostBefore=%@ frame=%@",
            message.id.uuidString,
            before,
            NSStringFromRect(panel.frame)
        )
        NSLog(
            "FQN navigation accessibilityGranted=%@",
            FinderPermissionCenter.accessibilityIsGranted().description
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let after = NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "<none>"
            NSLog("FQN panel frontmostAfter=%@", after)
        }
    }

    func dismiss() {
        removeEventMonitors()
        panel.orderOut(nil)
        currentMessage = nil
        sessionState.dismiss()
    }

    private func makePanel() -> NSPanel {
        let panel = QuickNavPanel(
            contentRect: CGRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.onCancelOperation = { [weak self] in
            self?.dismiss()
        }
        return panel
    }

    private func installEventMonitors() {
        guard localMouseMonitor == nil, globalMouseMonitor == nil else { return }

        let mouseEvents: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEvents) { [weak self] event in
            self?.dismissIfClickOutsidePanel()
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEvents) { [weak self] _ in
            Task { @MainActor in
                self?.dismissIfClickOutsidePanel()
            }
        }
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication else {
                return
            }
            // Clicking the path popover or the settings window activates our
            // own app; keep the panel open in that case. Only dismiss when the
            // user switches to another application.
            if application.bundleIdentifier != "com.apple.finder",
               application.bundleIdentifier != Bundle.main.bundleIdentifier {
                Task { @MainActor in
                    self?.dismiss()
                }
            }
        }
    }

    private func removeEventMonitors() {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
            self.workspaceObserver = nil
        }
    }

    private func dismissIfClickOutsidePanel() {
        guard panel.isVisible else { return }
        let clickPoint = NSEvent.mouseLocation
        let insideOwnWindow = NSApp.windows.contains { window in
            window.isVisible && window.frame.contains(clickPoint)
        }
        if !insideOwnWindow {
            dismiss()
        }
    }

    private func render(message: QuickNavBridgeMessage) {
        let currentURL = message.directoryURL
        let isFavorite = favoritesStore.entries.contains { $0.path == currentURL.path }
        let preferences = preferencesStore.preferences
        panel.contentView = NSHostingView(
            rootView: QuickNavPlaceholderView(
                directoryURL: currentURL,
                favoriteEntries: favoritesStore.entries.filter(\.isEnabled),
                recentEntries: recentsStore.entries,
                isFavorite: isFavorite,
                initialTab: sessionState.selectedTab,
                showFullPathOnHover: preferences.showFullPathOnHover,
                onBack: { [weak self] in self?.goBack() },
                onUp: { [weak self] in self?.goUp(from: message.directoryPath) },
                onOpenSettings: {
                    SettingsWindowController.shared.show()
                },
                onNavigate: { [weak self] url in self?.navigate(to: url) },
                onTabChanged: { [weak self] tab in
                    self?.sessionState.selectTab(tab)
                },
                onToggleFavorite: { [weak self] in self?.toggleFavorite(currentURL) },
                onManageFavorites: {
                    SettingsWindowController.shared.show(section: .favorites)
                }
            )
        )
    }

    private func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { $0.frame.contains(point) }
    }

    private func goBack() {
        do {
            try navigator.goBack()
            NSLog("FQN navigation action=back result=success")
            refreshCurrentDirectory(fallback: currentMessage?.directoryURL)
        } catch {
            NSLog("FQN navigation action=back result=error error=%@", String(describing: error))
        }
    }

    private func goUp(from path: String) {
        do {
            try navigator.goUp(from: URL(fileURLWithPath: path, isDirectory: true))
            NSLog("FQN navigation action=up result=success path=%@", path)
            let fallback = URL(fileURLWithPath: path, isDirectory: true).deletingLastPathComponent()
            refreshCurrentDirectory(fallback: fallback)
        } catch {
            NSLog("FQN navigation action=up result=error path=%@ error=%@", path, String(describing: error))
        }
    }

    private func navigate(to target: URL) {
        do {
            try navigator.navigate(to: target)
            NSLog("FQN navigation action=jump result=success path=%@", target.path)
            refreshCurrentDirectory(fallback: target)
        } catch {
            NSLog("FQN navigation action=jump result=error path=%@ error=%@", target.path, String(describing: error))
        }
    }

    private func refreshCurrentDirectory(fallback: URL?) {
        guard let currentMessage else { return }
        guard preferencesStore.preferences.keepPanelOpenAfterNavigation else {
            dismiss()
            return
        }
        let messageBeforeRefresh = currentMessage
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
            guard let self else { return }
            let target = (try? self.finderController.currentTarget())
                ?? fallback
                ?? messageBeforeRefresh.directoryURL
            let refreshed = QuickNavBridgeMessage(
                action: .show,
                id: messageBeforeRefresh.id,
                directoryURL: target.standardizedFileURL,
                mouseX: messageBeforeRefresh.mouseX,
                mouseY: messageBeforeRefresh.mouseY,
                timestamp: Date()
            )
            self.currentMessage = refreshed
            self.sessionState.didNavigate(to: target.standardizedFileURL)
            self.recentsStore.record(target)
            self.render(message: refreshed)
        }
    }

    private func toggleFavorite(_ url: URL) {
        if favoritesStore.entries.contains(where: { $0.path == url.standardizedFileURL.path }) {
            favoritesStore.remove(url)
            NSLog("FQN favorite action=remove path=%@", url.path)
        } else {
            favoritesStore.add(url)
            NSLog("FQN favorite action=add path=%@", url.path)
        }

        if let currentMessage {
            render(message: currentMessage)
        }
    }
}

private enum QuickNavTab: Hashable {
    case favorites
    case recents
}

private struct QuickNavPlaceholderView: View {
    let directoryURL: URL
    let favoriteEntries: [FolderEntry]
    let recentEntries: [FolderEntry]
    let isFavorite: Bool
    let initialTab: QuickNavTabPreference
    let showFullPathOnHover: Bool
    let onBack: () -> Void
    let onUp: () -> Void
    let onOpenSettings: () -> Void
    let onNavigate: (URL) -> Void
    let onTabChanged: (QuickNavTabPreference) -> Void
    let onToggleFavorite: () -> Void
    let onManageFavorites: () -> Void

    @State private var selectedTab: QuickNavTab
    @State private var hoveredEntryID: String?

    init(
        directoryURL: URL,
        favoriteEntries: [FolderEntry],
        recentEntries: [FolderEntry],
        isFavorite: Bool,
        initialTab: QuickNavTabPreference,
        showFullPathOnHover: Bool,
        onBack: @escaping () -> Void,
        onUp: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        onNavigate: @escaping (URL) -> Void,
        onTabChanged: @escaping (QuickNavTabPreference) -> Void,
        onToggleFavorite: @escaping () -> Void,
        onManageFavorites: @escaping () -> Void
    ) {
        self.directoryURL = directoryURL
        self.favoriteEntries = favoriteEntries
        self.recentEntries = recentEntries
        self.isFavorite = isFavorite
        self.initialTab = initialTab
        self.showFullPathOnHover = showFullPathOnHover
        self.onBack = onBack
        self.onUp = onUp
        self.onOpenSettings = onOpenSettings
        self.onNavigate = onNavigate
        self.onTabChanged = onTabChanged
        self.onToggleFavorite = onToggleFavorite
        self.onManageFavorites = onManageFavorites
        _selectedTab = State(initialValue: initialTab == .favorites ? .favorites : .recents)
    }

    private var folderName: String {
        directoryURL.lastPathComponent
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
                Text(folderName.isEmpty ? "快速导航" : folderName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("打开 man导 偏好设置")
            }
            .help("拖动此处移动快速导航卡片")

            HStack(spacing: 8) {
                shortcut("arrow.uturn.backward", "上一位置", action: onBack)
                shortcut("arrow.up", "上层文件夹", action: onUp)
            }

            QuickNavPathView(
                directoryURL: directoryURL,
                showFullPathOnHover: showFullPathOnHover,
                onNavigate: onNavigate
            )

            Picker("", selection: $selectedTab) {
                Text("收藏").tag(QuickNavTab.favorites)
                Text("最近访问").tag(QuickNavTab.recents)
            }
            .pickerStyle(.segmented)
            .animation(.easeInOut(duration: 0.18), value: selectedTab)
            .onChange(of: selectedTab) { _, newValue in
                onTabChanged(newValue == .favorites ? .favorites : .recents)
            }

            let entries = selectedTab == .favorites ? favoriteEntries : recentEntries
            if entries.isEmpty {
                Text(selectedTab == .favorites ? "暂无收藏" : "暂无最近访问")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(entries) { entry in
                            destination(entry)
                        }
                    }
                }
                .frame(maxHeight: 92)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            Divider()

            HStack(spacing: 10) {
                Button(action: onToggleFavorite) {
                    HStack {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                        Text(isFavorite ? "取消收藏当前位置" : "收藏当前位置")
                        Spacer()
                    }
                    .font(.callout)
                }
                .buttonStyle(.plain)

                Button("管理收藏…", action: onManageFavorites)
                    .font(.caption)
                    .buttonStyle(.link)
            }
        }
        .padding(14)
        .frame(width: 292, height: 286)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func shortcut(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(.callout.weight(.medium))
            .padding(.horizontal, 9)
            .frame(height: 34)
            .background(.primary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func destination(_ entry: FolderEntry) -> some View {
        Button(action: { onNavigate(entry.url) }) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .frame(width: 16)
                    .foregroundStyle(hoveredEntryID == entry.id ? .white : .secondary)
                Text(entry.displayName)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .font(.callout)
            .foregroundStyle(hoveredEntryID == entry.id ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hoveredEntryID == entry.id ? Color.accentColor : Color.clear)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                hoveredEntryID = hovering ? entry.id : nil
            }
        }
    }
}
