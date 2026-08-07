import Foundation
import Darwin

enum MonitoredRootResolver {
    static func accountHomePath() -> String? {
        guard let record = getpwuid(getuid()),
              let homePointer = record.pointee.pw_dir else {
            return nil
        }

        return String(cString: homePointer)
    }

    static func homeURL(
        accountHomePath: String? = accountHomePath(),
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fallback: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> URL {
        for homePath in [accountHomePath, environment["HOME"]].compactMap({ $0 }) {
            guard !homePath.isEmpty, homePath.hasPrefix("/") else { continue }
            return URL(fileURLWithPath: homePath, isDirectory: true).standardizedFileURL
        }

        return fallback
    }
}
