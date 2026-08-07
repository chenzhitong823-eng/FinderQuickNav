import AppKit
import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject var model: SettingsWindowModel

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 700, minHeight: 460)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("man导")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 8)

            ForEach(SettingsSection.allCases) { section in
                Button {
                    model.selectedSection = section
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: section.symbolName)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(section.title)
                                .font(.callout.weight(.medium))
                            Text(section.subtitle)
                                .font(.caption)
                                .foregroundStyle(model.selectedSection == section ? .white.opacity(0.75) : .secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(model.selectedSection == section ? .white : .primary)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(model.selectedSection == section ? Color.accentColor : Color.clear)
                }
                .padding(.horizontal, 8)
            }

            Spacer()

            Text("发送到功能将在后续版本加入")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(16)
        }
        .frame(width: 205)
        .frame(maxHeight: .infinity)
        .background(.quaternary.opacity(0.28))
    }

    @ViewBuilder
    private var detail: some View {
        switch model.selectedSection {
        case .quickNavigation:
            QuickNavigationSettingsPage()
        case .favorites:
            FavoritesSettingsPage()
        case .newFiles:
            NewFilesSettingsPage()
        case .permissions:
            PermissionsSettingsPage()
        }
    }
}

@MainActor
private struct SettingsPageHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(description)
                .foregroundStyle(.secondary)
        }
    }
}

@MainActor
private struct QuickNavigationSettingsPage: View {
    private let store: QuickNavPreferencesStore
    @State private var preferences: QuickNavPreferences

    init(store: QuickNavPreferencesStore = QuickNavPreferencesStore()) {
        self.store = store
        _preferences = State(initialValue: store.preferences)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: "快速导航",
                description: "控制卡片的连续操作方式和路径展示。"
            )

            GroupBox("卡片行为") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("导航后保持卡片打开", isOn: Binding(
                        get: { preferences.keepPanelOpenAfterNavigation },
                        set: { preferences.keepPanelOpenAfterNavigation = $0 }
                    ))
                    Toggle("悬停时显示完整路径", isOn: Binding(
                        get: { preferences.showFullPathOnHover },
                        set: { preferences.showFullPathOnHover = $0 }
                    ))
                }
                .padding(4)
            }

            GroupBox("默认显示") {
                Picker("打开卡片时显示", selection: Binding(
                    get: { preferences.defaultTab },
                    set: { preferences.defaultTab = $0 }
                )) {
                    Text("快速收藏").tag(QuickNavTabPreference.favorites)
                    Text("最近访问").tag(QuickNavTabPreference.recents)
                }
                .pickerStyle(.radioGroup)
                .padding(4)
            }

            Spacer()
        }
        .padding(28)
        .onChange(of: preferences) { _, newValue in
            store.update(newValue)
        }
    }

}

@MainActor
private struct FavoritesSettingsPage: View {
    private let store: FavoritesStore
    @State private var entries: [FolderEntry]

    init(store: FavoritesStore = FavoritesStore()) {
        self.store = store
        _entries = State(initialValue: store.entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SettingsPageHeader(
                    title: "个人收藏",
                    description: "这些目录会出现在快速导航的收藏分页中。"
                )
                Spacer()
                Button {
                    addFolder()
                } label: {
                    Label("添加目录", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if entries.isEmpty {
                ContentUnavailableView("暂无收藏", systemImage: "star", description: Text("从 Finder 卡片点击“收藏当前位置”，或在这里添加目录。"))
            } else {
                List {
                    ForEach(entries) { entry in
                        favoriteRow(entry)
                    }
                    .onMove(perform: move)
                }
                .listStyle(.inset)
            }
        }
        .padding(28)
        .onAppear(perform: reload)
    }

    private func favoriteRow(_ entry: FolderEntry) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 3) {
                TextField("显示名称", text: displayNameBinding(for: entry)) {
                    commitName(for: entry)
                }
                .textFieldStyle(.plain)
                Text(entry.path)
                    .font(.caption)
                    .foregroundStyle(entry.fileExists ? Color.secondary : Color.orange)
                    .lineLimit(1)
            }
            Spacer()
            Toggle("启用", isOn: enabledBinding(for: entry))
                .labelsHidden()
            VStack(spacing: 1) {
                Button {
                    move(entry, by: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                .disabled(entries.first?.path == entry.path)
                Button {
                    move(entry, by: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                .disabled(entries.last?.path == entry.path)
            }
            Button(role: .destructive) {
                store.remove(entry.url)
                reload()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "添加"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.add(url)
        reload()
    }

    private func reload() {
        entries = store.entries
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        guard let source = offsets.first, entries.indices.contains(source) else { return }
        store.move(path: entries[source].path, to: destination)
        reload()
    }

    private func move(_ entry: FolderEntry, by offset: Int) {
        guard let source = entries.firstIndex(where: { $0.path == entry.path }) else { return }
        let destination = min(max(0, source + offset), max(0, entries.count - 1))
        store.move(path: entry.path, to: destination)
        reload()
    }

    private func displayNameBinding(for entry: FolderEntry) -> Binding<String> {
        Binding(
            get: { entries.first(where: { $0.path == entry.path })?.displayName ?? entry.displayName },
            set: { value in
                guard let index = entries.firstIndex(where: { $0.path == entry.path }) else { return }
                entries[index].displayName = value
            }
        )
    }

    private func enabledBinding(for entry: FolderEntry) -> Binding<Bool> {
        Binding(
            get: { entries.first(where: { $0.path == entry.path })?.isEnabled ?? entry.isEnabled },
            set: { value in
                store.setEnabled(path: entry.path, value)
                reload()
            }
        )
    }

    private func commitName(for entry: FolderEntry) {
        guard let current = entries.first(where: { $0.path == entry.path }) else { return }
        store.rename(path: entry.path, displayName: current.displayName)
        reload()
    }
}

@MainActor
private struct NewFilesSettingsPage: View {
    private let store: NewFilePreferencesStore
    @State private var entries: [NewFileMenuEntry]

    init(store: NewFilePreferencesStore = NewFilePreferencesStore()) {
        self.store = store
        _entries = State(initialValue: store.entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsPageHeader(
                title: "新建文件",
                description: "调整 Finder 空白处“新建文件”子菜单的显示和顺序。"
            )

            List {
                ForEach(entries) { entry in
                    HStack(spacing: 10) {
                        Image(systemName: entry.action == .createFolder ? "folder" : "doc")
                            .frame(width: 22)
                            .foregroundStyle(.blue)
                        Text(entry.title)
                        Spacer()
                        Toggle("启用", isOn: enabledBinding(for: entry))
                            .labelsHidden()
                        VStack(spacing: 1) {
                            Button {
                                move(entry, by: -1)
                            } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.borderless)
                            .disabled(entries.first?.action == entry.action)
                            Button {
                                move(entry, by: 1)
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.borderless)
                            .disabled(entries.last?.action == entry.action)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(.inset)
        }
        .padding(28)
        .onAppear(perform: reload)
    }

    private func reload() {
        entries = store.entries
    }

    private func enabledBinding(for entry: NewFileMenuEntry) -> Binding<Bool> {
        Binding(
            get: { entries.first(where: { $0.action == entry.action })?.isEnabled ?? entry.isEnabled },
            set: { value in
                store.setEnabled(action: entry.action, value)
                reload()
            }
        )
    }

    private func move(from offsets: IndexSet, to destination: Int) {
        guard let source = offsets.first, entries.indices.contains(source) else { return }
        store.move(action: entries[source].action, to: destination)
        reload()
    }

    private func move(_ entry: NewFileMenuEntry, by offset: Int) {
        guard let source = entries.firstIndex(where: { $0.action == entry.action }) else { return }
        let destination = min(max(0, source + offset), max(0, entries.count - 1))
        store.move(action: entry.action, to: destination)
        reload()
    }
}

@MainActor
private struct PermissionsSettingsPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsPageHeader(
                title: "权限与扩展",
                description: "快速导航需要 Finder 扩展和少量系统权限才能控制当前窗口。"
            )

            GroupBox("辅助功能") {
                HStack {
                    Image(systemName: FinderPermissionCenter.accessibilityIsGranted() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(FinderPermissionCenter.accessibilityIsGranted() ? .green : .orange)
                    Text(FinderPermissionCenter.accessibilityIsGranted() ? "已授权" : "尚未授权")
                    Spacer()
                    Button("打开系统设置") {
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                        NSWorkspace.shared.open(url)
                    }
                }
                .padding(4)
            }

            GroupBox("Finder 自动化") {
                Text("首次执行目录跳转时，macOS 可能会请求允许 FinderQuickNav 控制 Finder。")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
            }

            Spacer()
        }
        .padding(28)
    }
}
