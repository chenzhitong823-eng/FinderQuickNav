import Foundation

struct QuickNavSessionState: Equatable {
    private(set) var isPresented = false
    private(set) var currentDirectory: URL?
    private(set) var selectedTab: QuickNavTabPreference = .favorites

    mutating func present(
        directory: URL,
        defaultTab: QuickNavTabPreference = .favorites
    ) {
        isPresented = true
        currentDirectory = directory.standardizedFileURL
        selectedTab = defaultTab
    }

    mutating func selectTab(_ tab: QuickNavTabPreference) {
        guard isPresented else { return }
        selectedTab = tab
    }

    mutating func didNavigate(to directory: URL) {
        guard isPresented else { return }
        currentDirectory = directory.standardizedFileURL
    }

    mutating func dismiss() {
        isPresented = false
    }
}
