import Foundation

protocol FinderWindowControlling {
    var isFinderFrontmost: Bool { get }

    func activateFinder() -> Bool
    func sendBackShortcut() throws
    func sendUpShortcut() throws
    func setFrontWindowTarget(_ directory: URL) throws
    func currentTarget() throws -> URL
}

protocol FinderNavigating {
    func goBack() throws
    func goUp(from current: URL) throws
    func navigate(to directory: URL) throws
}

enum FinderNavigationError: Error, Equatable {
    case finderNotFrontmost
    case noFinderWindow
    case accessibilityDenied
    case automationDenied
    case invalidDirectory
    case operationFailed(Int)
}

final class FinderNavigator: FinderNavigating {
    private let controller: FinderWindowControlling
    private let fileManager: FileManager

    init(
        controller: FinderWindowControlling,
        fileManager: FileManager = .default
    ) {
        self.controller = controller
        self.fileManager = fileManager
    }

    func goBack() throws {
        try requireFinderFrontmost()
        try controller.sendBackShortcut()
    }

    func goUp(from current: URL) throws {
        try requireFinderFrontmost()

        let directory = current.standardizedFileURL
        guard directory.isFileURL,
              directory.path != "/",
              directory.deletingLastPathComponent().path != directory.path else {
            throw FinderNavigationError.invalidDirectory
        }

        try controller.sendUpShortcut()
    }

    func navigate(to directory: URL) throws {
        try requireFinderFrontmost()

        let target = directory.standardizedFileURL
        var isDirectory: ObjCBool = false
        guard target.isFileURL,
              fileManager.fileExists(atPath: target.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw FinderNavigationError.invalidDirectory
        }

        try controller.setFrontWindowTarget(target)
    }

    private func requireFinderFrontmost() throws {
        if controller.isFinderFrontmost {
            return
        }

        guard controller.activateFinder(), controller.isFinderFrontmost else {
            throw FinderNavigationError.finderNotFrontmost
        }
    }
}
