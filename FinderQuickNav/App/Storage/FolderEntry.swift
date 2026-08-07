import Foundation

struct FolderEntry: Codable, Equatable, Identifiable, Sendable {
    let path: String
    var displayName: String
    var isEnabled: Bool

    var id: String { path }

    var url: URL {
        URL(fileURLWithPath: path, isDirectory: true)
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: path)
    }

    init?(url: URL, displayName: String? = nil, isEnabled: Bool = true) {
        guard url.isFileURL, !url.path.isEmpty else { return nil }
        self.path = url.standardizedFileURL.path
        let fallback = url.lastPathComponent.isEmpty ? self.path : url.lastPathComponent
        self.displayName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? displayName!.trimmingCharacters(in: .whitespacesAndNewlines)
            : fallback
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case path
        case displayName
        case isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedPath = try container.decode(String.self, forKey: .path)
        self.path = decodedPath
        let url = URL(fileURLWithPath: decodedPath, isDirectory: true)
        let fallback = url.lastPathComponent.isEmpty ? decodedPath : url.lastPathComponent
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? fallback
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
}
