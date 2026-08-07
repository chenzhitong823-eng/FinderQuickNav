import Foundation
import Darwin

enum NewFileKind: CaseIterable, Equatable, Sendable {
    case folder
    case text
    case markdown
    case word
    case excel
    case powerPoint

    var fileExtension: String {
        switch self {
        case .folder: return ""
        case .text: return "txt"
        case .markdown: return "md"
        case .word: return "docx"
        case .excel: return "xlsx"
        case .powerPoint: return "pptx"
        }
    }

    var menuTitle: String {
        switch self {
        case .folder: return "文件夹"
        case .text: return "TXT 文本"
        case .markdown: return "Markdown"
        case .word: return "Word 文档"
        case .excel: return "Excel 工作簿"
        case .powerPoint: return "PowerPoint 演示文稿"
        }
    }

    var templateFileName: String? {
        switch self {
        case .folder, .text, .markdown: return nil
        case .word: return "blank.docx"
        case .excel: return "blank.xlsx"
        case .powerPoint: return "blank.pptx"
        }
    }
}

enum NewFileError: Error, Equatable {
    case invalidDirectory
    case cannotCreate
    case templateMissing
    case templateInvalid
}

final class NewFileService {
    private enum CreateAttempt {
        case created
        case alreadyExists
    }

    private let fileManager: FileManager
    private let templateDirectory: URL?

    init(
        fileManager: FileManager = .default,
        templateDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        self.templateDirectory = templateDirectory ?? Self.defaultTemplateDirectory()
    }

    func create(kind: NewFileKind, in directory: URL) throws -> URL {
        let targetDirectory = directory.standardizedFileURL
        guard targetDirectory.isFileURL,
              isDirectory(targetDirectory) else {
            throw NewFileError.invalidDirectory
        }

        if kind == .folder {
            return try createFolder(in: targetDirectory)
        }

        let contents = try contents(for: kind)
        for suffix in 1...10_000 {
            let destination = targetURL(in: targetDirectory, suffix: suffix, kind: kind)
            switch try createExclusively(contents, at: destination) {
            case .created:
                return destination
            case .alreadyExists:
                continue
            }
        }

        throw NewFileError.cannotCreate
    }

    private func contents(for kind: NewFileKind) throws -> Data {
        guard let templateFileName = kind.templateFileName else {
            return Data()
        }

        guard let templateDirectory,
              fileManager.fileExists(atPath: templateDirectory.path) else {
            throw NewFileError.templateMissing
        }

        let templateURL = templateDirectory.appendingPathComponent(templateFileName)
        guard fileManager.fileExists(atPath: templateURL.path) else {
            throw NewFileError.templateMissing
        }

        let data: Data
        do {
            data = try Data(contentsOf: templateURL)
        } catch {
            throw NewFileError.templateInvalid
        }

        guard data.count >= 4,
              data.prefix(4) == Data([0x50, 0x4B, 0x03, 0x04]) else {
            throw NewFileError.templateInvalid
        }
        return data
    }

    private func targetURL(in directory: URL, suffix: Int, kind: NewFileKind) -> URL {
        let baseName = suffix == 1 ? "未命名" : "未命名 \(suffix)"
        let fileName = kind.fileExtension.isEmpty
            ? baseName
            : "\(baseName).\(kind.fileExtension)"
        return directory.appendingPathComponent(fileName)
    }

    private func createFolder(in directory: URL) throws -> URL {
        for suffix in 1...10_000 {
            let destination = targetURL(in: directory, suffix: suffix, kind: .folder)
            do {
                try fileManager.createDirectory(at: destination, withIntermediateDirectories: false)
                return destination
            } catch {
                if fileManager.fileExists(atPath: destination.path) {
                    continue
                }
                throw NewFileError.cannotCreate
            }
        }

        throw NewFileError.cannotCreate
    }

    private func isDirectory(_ url: URL) -> Bool {
        var directory = ObjCBool(false)
        return fileManager.fileExists(atPath: url.path, isDirectory: &directory)
            && directory.boolValue
    }

    private func createExclusively(_ data: Data, at url: URL) throws -> CreateAttempt {
        let descriptor = Darwin.open(
            url.path,
            O_WRONLY | O_CREAT | O_EXCL,
            mode_t(0o644)
        )

        guard descriptor >= 0 else {
            if Darwin.errno == EEXIST {
                return .alreadyExists
            }
            throw NewFileError.cannotCreate
        }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        do {
            try handle.write(contentsOf: data)
            try handle.close()
            return .created
        } catch {
            try? handle.close()
            try? fileManager.removeItem(at: url)
            throw NewFileError.cannotCreate
        }
    }

    private static func defaultTemplateDirectory(bundle: Bundle = .main) -> URL? {
        guard let resourceURL = bundle.resourceURL else { return nil }
        let nestedTemplates = resourceURL.appendingPathComponent("Templates", isDirectory: true)
        if FileManager.default.fileExists(atPath: nestedTemplates.path) {
            return nestedTemplates
        }
        return resourceURL
    }
}
