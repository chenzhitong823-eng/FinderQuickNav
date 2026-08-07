import Foundation
import CoreGraphics

enum ExtensionRequestURLBuilder {
    static func showURL(
        directoryURL: URL,
        mouseLocation: CGPoint,
        timestamp: Date = Date()
    ) -> URL? {
        guard directoryURL.isFileURL else { return nil }

        var components = URLComponents()
        components.scheme = "finderquicknav"
        components.host = "show"
        components.queryItems = [
            URLQueryItem(name: "path", value: directoryURL.path),
            URLQueryItem(name: "x", value: String(Double(mouseLocation.x))),
            URLQueryItem(name: "y", value: String(Double(mouseLocation.y))),
            URLQueryItem(name: "ts", value: String(timestamp.timeIntervalSince1970))
        ]
        return components.url
    }
}
