import Foundation

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

func expectError(
    _ operation: () throws -> Void,
    _ expected: NewFileError,
    _ message: String
) {
    do {
        try operation()
        fatalError("Expected \(expected): \(message)")
    } catch let error as NewFileError {
        guard error == expected else {
            fatalError("Expected \(expected), got \(error): \(message)")
        }
    } catch {
        fatalError("Unexpected error \(error): \(message)")
    }
}

func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("FinderQuickNav-NewFile-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

let root = try makeTemporaryDirectory()
defer { try? FileManager.default.removeItem(at: root) }

let sourceTemplateDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent("App/NewFile/Templates", isDirectory: true)
let service = NewFileService(templateDirectory: sourceTemplateDirectory)

let expectedExtensions: [(NewFileKind, String)] = [
    (.folder, ""),
    (.text, "txt"),
    (.markdown, "md"),
    (.word, "docx"),
    (.excel, "xlsx"),
    (.powerPoint, "pptx")
]

for (kind, fileExtension) in expectedExtensions {
    expect(kind.fileExtension == fileExtension, "Unexpected extension for \(kind)")
}

let existingFolder = root.appendingPathComponent("未命名", isDirectory: true)
try FileManager.default.createDirectory(at: existingFolder, withIntermediateDirectories: true)
let createdFolder = try service.create(kind: .folder, in: root)
expect(createdFolder.lastPathComponent == "未命名 2", "Folder collision should use a new name")
expect(FileManager.default.fileExists(atPath: createdFolder.path), "Folder was not created")

let oldMarkdown = root.appendingPathComponent("未命名.md")
FileManager.default.createFile(atPath: oldMarkdown.path, contents: Data("old".utf8))
let createdMarkdown = try service.create(kind: .markdown, in: root)
expect(createdMarkdown.lastPathComponent == "未命名 2.md", "Markdown collision should use a new name")
let oldMarkdownContents = try String(contentsOf: oldMarkdown, encoding: .utf8)
expect(oldMarkdownContents == "old", "Existing Markdown must never be overwritten")

let unicodeDirectory = root.appendingPathComponent("课程 作业", isDirectory: true)
try FileManager.default.createDirectory(at: unicodeDirectory, withIntermediateDirectories: true)
let createdText = try service.create(kind: .text, in: unicodeDirectory)
expect(createdText.path.contains("课程 作业"), "Unicode directory path was not preserved")
expect(createdText.pathExtension == "txt", "Text file extension is incorrect")

let createdWord = try service.create(kind: .word, in: root)
let createdExcel = try service.create(kind: .excel, in: root)
let createdPowerPoint = try service.create(kind: .powerPoint, in: root)
for file in [createdWord, createdExcel, createdPowerPoint] {
    expect(FileManager.default.fileExists(atPath: file.path), "Expected generated file \(file.lastPathComponent)")
    let validZip = try isValidZip(file)
    expect(validZip, "Generated OOXML file is not a valid ZIP: \(file.lastPathComponent)")
}

let missingTemplates = root.appendingPathComponent("missing-templates", isDirectory: true)
try FileManager.default.createDirectory(at: missingTemplates, withIntermediateDirectories: true)
let missingTemplateService = NewFileService(templateDirectory: missingTemplates)
expectError(
    { _ = try missingTemplateService.create(kind: .word, in: root) },
    .templateMissing,
    "A missing OOXML template must be reported"
)

let readOnlyDirectory = root.appendingPathComponent("read-only", isDirectory: true)
try FileManager.default.createDirectory(at: readOnlyDirectory, withIntermediateDirectories: true)
try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: readOnlyDirectory.path)
defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: readOnlyDirectory.path) }
expectError(
    { _ = try service.create(kind: .text, in: readOnlyDirectory) },
    .cannotCreate,
    "A read-only directory must not produce a partial result"
)

print("new file service smoke test passed")

func isValidZip(_ file: URL) throws -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    process.arguments = ["-t", file.path]
    process.standardOutput = Pipe()
    process.standardError = Pipe()
    try process.run()
    process.waitUntilExit()
    return process.terminationStatus == 0
}
