import Foundation

struct FolderPathComponent: Equatable, Identifiable, Sendable {
    let url: URL

    var id: String { url.standardizedFileURL.path }

    var label: String {
        url.path == "/" ? "/" : url.lastPathComponent
    }
}

struct FolderPathDisplay: Equatable, Sendable {
    let url: URL

    init(url: URL) {
        self.url = url.standardizedFileURL
    }

    var compactLabel: String {
        url.path == "/" ? "/" : (url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
    }

    var fullPath: String {
        url.path
    }

    var components: [FolderPathComponent] {
        var result: [FolderPathComponent] = []
        var current = URL(fileURLWithPath: "/", isDirectory: true)
        result.append(FolderPathComponent(url: current))

        for component in url.pathComponents.dropFirst() {
            current.appendPathComponent(component, isDirectory: true)
            result.append(FolderPathComponent(url: current))
        }
        return result
    }
}
