import Foundation

enum QuickNavAction: String, Codable, Sendable {
    case show
    case createFolder = "create-folder"
    case createText = "create-text"
    case createMarkdown = "create-markdown"
    case createWord = "create-word"
    case createExcel = "create-excel"
    case createPowerPoint = "create-powerpoint"
}

struct QuickNavBridgeMessage: Codable, Equatable, Sendable {
    let action: QuickNavAction
    let id: UUID
    let directoryURL: URL
    let mouseX: Double
    let mouseY: Double
    let timestamp: Date

    var directoryPath: String {
        directoryURL.path
    }
}

enum QuickNavRequestError: Error, Equatable {
    case invalidPayload
    case unsupportedAction
    case expired
    case nonFileURL
    case notDirectory
    case invalidMouseLocation
}

private struct QuickNavWireMessage: Codable {
    let action: String
    let id: UUID
    let directoryURL: URL
    let mouseX: Double
    let mouseY: Double
    let timestamp: Date
}

enum QuickNavBridgeCodec {
    static let maximumAge: TimeInterval = 5

    static func encode(_ message: QuickNavBridgeMessage) throws -> String {
        let wireMessage = QuickNavWireMessage(
            action: message.action.rawValue,
            id: message.id,
            directoryURL: message.directoryURL,
            mouseX: message.mouseX,
            mouseY: message.mouseY,
            timestamp: message.timestamp
        )
        let data = try JSONEncoder().encode(wireMessage)
        guard let payload = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return payload
    }

    static func decode(
        _ payload: String,
        now: Date = Date(),
        maximumAge: TimeInterval = maximumAge,
        fileManager: FileManager = .default
    ) throws -> QuickNavBridgeMessage {
        guard let data = payload.data(using: .utf8) else {
            throw QuickNavRequestError.invalidPayload
        }

        let wireMessage: QuickNavWireMessage
        do {
            wireMessage = try JSONDecoder().decode(QuickNavWireMessage.self, from: data)
        } catch {
            if let rawAction = try? JSONDecoder().decode(RawAction.self, from: data),
               QuickNavAction(rawValue: rawAction.action) == nil {
                throw QuickNavRequestError.unsupportedAction
            }
            throw QuickNavRequestError.invalidPayload
        }

        guard let action = QuickNavAction(rawValue: wireMessage.action) else {
            throw QuickNavRequestError.unsupportedAction
        }
        guard abs(now.timeIntervalSince(wireMessage.timestamp)) <= maximumAge else {
            throw QuickNavRequestError.expired
        }
        guard wireMessage.mouseX.isFinite, wireMessage.mouseY.isFinite else {
            throw QuickNavRequestError.invalidMouseLocation
        }
        guard wireMessage.directoryURL.isFileURL,
              !wireMessage.directoryURL.path.isEmpty else {
            throw QuickNavRequestError.nonFileURL
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(
            atPath: wireMessage.directoryURL.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            throw QuickNavRequestError.notDirectory
        }

        return QuickNavBridgeMessage(
            action: action,
            id: wireMessage.id,
            directoryURL: wireMessage.directoryURL.standardizedFileURL,
            mouseX: wireMessage.mouseX,
            mouseY: wireMessage.mouseY,
            timestamp: wireMessage.timestamp
        )
    }

    private struct RawAction: Decodable {
        let action: String
    }
}

struct QuickNavRequestDeduplicator {
    private var seenIDs: Set<UUID> = []
    private let maximumRememberedIDs = 128

    mutating func accept(_ id: UUID) -> Bool {
        guard !seenIDs.contains(id) else { return false }
        seenIDs.insert(id)
        if seenIDs.count > maximumRememberedIDs {
            seenIDs.removeFirst()
        }
        return true
    }
}

enum QuickNavDistributedBridge {
    static let notificationName = Notification.Name("local.finderquicknav.bridge.show")

    static func post(_ message: QuickNavBridgeMessage) throws {
        let payload = try QuickNavBridgeCodec.encode(message)
        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: payload,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
