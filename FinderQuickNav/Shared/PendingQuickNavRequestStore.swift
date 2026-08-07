import Foundation

enum QuickNavHostLaunch {
    static let bundleIdentifier = "local.finderquicknav.app"
}

enum PendingQuickNavRequestStore {
    static let defaultSuiteName = "group.local.finderquicknav"
    static let pendingKey = "PendingQuickNavRequest"
    static let maximumAge: TimeInterval = 10

    static func save(
        _ message: QuickNavBridgeMessage,
        suiteName: String = defaultSuiteName
    ) throws {
        let payload = try QuickNavBridgeCodec.encode(message)
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw PendingQuickNavRequestStoreError.unavailableDefaults
        }
        defaults.set(payload, forKey: pendingKey)
    }

    static func takePending(
        now: Date = Date(),
        suiteName: String = defaultSuiteName
    ) -> QuickNavBridgeMessage? {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let payload = defaults.string(forKey: pendingKey) else {
            return nil
        }
        defaults.removeObject(forKey: pendingKey)
        guard let message = try? QuickNavBridgeCodec.decode(
            payload,
            now: now,
            maximumAge: maximumAge
        ) else {
            return nil
        }
        return message
    }

    static func clear(suiteName: String = defaultSuiteName) {
        UserDefaults(suiteName: suiteName)?.removeObject(forKey: pendingKey)
    }
}

enum PendingQuickNavRequestStoreError: Error {
    case unavailableDefaults
}
