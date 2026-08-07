#!/usr/bin/env swift

import AppKit
import Foundation

enum IconPreparationError: LocalizedError {
    case usage
    case unreadableSource(String)
    case cannotCreateBitmap
    case cannotEncodePNG

    var errorDescription: String? {
        switch self {
        case .usage:
            return "Usage: prepare-user-app-icon.swift <source.png> <output.png>"
        case let .unreadableSource(path):
            return "Unable to read source icon: \(path)"
        case .cannotCreateBitmap:
            return "Unable to allocate an RGBA icon bitmap."
        case .cannotEncodePNG:
            return "Unable to encode the prepared icon as PNG."
        }
    }
}

func prepareIcon(sourceURL: URL, outputURL: URL) throws {
    guard let sourceImage = NSImage(contentsOf: sourceURL) else {
        throw IconPreparationError.unreadableSource(sourceURL.path)
    }

    let canvasSize = NSSize(width: 1024, height: 1024)
    let canvasRect = NSRect(origin: .zero, size: canvasSize)
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw IconPreparationError.cannotCreateBitmap
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphicsContext
    graphicsContext.cgContext.clear(canvasRect)

    // This is the original macOS-style rounded-square boundary. It only removes
    // the screenshot's outer checkerboard; all artwork within the icon stays intact.
    NSBezierPath(roundedRect: canvasRect, xRadius: 260, yRadius: 260).addClip()
    // The supplied screenshot carries a narrow baked checkerboard strip on its
    // right edge. Crop only that strip before scaling; the character artwork is
    // otherwise drawn from the original pixels unchanged.
    let sourceArtworkRect = NSRect(
        x: 0,
        y: 0,
        width: sourceImage.size.width - 54,
        height: sourceImage.size.height
    )
    sourceImage.draw(
        in: canvasRect,
        from: sourceArtworkRect,
        operation: .copy,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw IconPreparationError.cannotEncodePNG
    }
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try pngData.write(to: outputURL, options: .atomic)
}

do {
    guard CommandLine.arguments.count == 3 else {
        throw IconPreparationError.usage
    }
    try prepareIcon(
        sourceURL: URL(fileURLWithPath: CommandLine.arguments[1]),
        outputURL: URL(fileURLWithPath: CommandLine.arguments[2])
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
