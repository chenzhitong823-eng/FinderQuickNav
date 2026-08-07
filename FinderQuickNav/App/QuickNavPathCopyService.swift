import AppKit
import Foundation

enum QuickNavPathCopyService {
    static func copy(
        _ path: String,
        pasteboard: NSPasteboard = .general
    ) -> String {
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
        return path
    }
}
