import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate-app-icon.swift <output-directory>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

let iconSizes = [16, 32, 64, 128, 256, 512, 1024]

for size in iconSizes {
    guard let image = drawIcon(size: size) else {
        fputs("could not draw icon at size \(size)\n", stderr)
        exit(1)
    }

    let outputURL = outputDirectory.appendingPathComponent("icon_\(size)x\(size).png")
    guard let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        fputs("could not create PNG destination for \(outputURL.path)\n", stderr)
        exit(1)
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fputs("could not write \(outputURL.path)\n", stderr)
        exit(1)
    }
}

func drawIcon(size: Int) -> CGImage? {
    let side = CGFloat(size)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    context.clear(CGRect(x: 0, y: 0, width: side, height: side))

    let backgroundRect = CGRect(
        x: side * 0.045,
        y: side * 0.045,
        width: side * 0.91,
        height: side * 0.91
    )
    let backgroundPath = CGPath(
        roundedRect: backgroundRect,
        cornerWidth: side * 0.205,
        cornerHeight: side * 0.205,
        transform: nil
    )

    context.saveGState()
    context.addPath(backgroundPath)
    context.clip()
    let colors = [
        CGColor(red: 0.16, green: 0.49, blue: 0.98, alpha: 1),
        CGColor(red: 0.19, green: 0.27, blue: 0.82, alpha: 1)
    ] as CFArray
    let locations: [CGFloat] = [0, 1]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: side * 0.15, y: side * 0.92),
            end: CGPoint(x: side * 0.88, y: side * 0.08),
            options: []
        )
    }
    context.restoreGState()

    context.saveGState()
    context.addPath(backgroundPath)
    context.setStrokeColor(CGColor(red: 0.75, green: 0.9, blue: 1, alpha: 0.42))
    context.setLineWidth(max(1, side * 0.012))
    context.strokePath()
    context.restoreGState()

    let folderBody = CGRect(
        x: side * 0.17,
        y: side * 0.255,
        width: side * 0.66,
        height: side * 0.385
    )
    let folderPath = CGPath(
        roundedRect: folderBody,
        cornerWidth: side * 0.055,
        cornerHeight: side * 0.055,
        transform: nil
    )
    context.setFillColor(CGColor(red: 0.55, green: 0.79, blue: 1, alpha: 1))
    context.addPath(folderPath)
    context.fillPath()

    let folderTab = CGRect(
        x: side * 0.23,
        y: side * 0.60,
        width: side * 0.245,
        height: side * 0.125
    )
    let tabPath = CGPath(
        roundedRect: folderTab,
        cornerWidth: side * 0.04,
        cornerHeight: side * 0.04,
        transform: nil
    )
    context.setFillColor(CGColor(red: 0.68, green: 0.87, blue: 1, alpha: 1))
    context.addPath(tabPath)
    context.fillPath()

    context.saveGState()
    context.addPath(folderPath)
    context.clip()
    let folderHighlight = CGRect(
        x: folderBody.minX,
        y: folderBody.maxY - side * 0.09,
        width: folderBody.width,
        height: side * 0.09
    )
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))
    context.fill(folderHighlight)
    context.restoreGState()

    let arrowStart = CGPoint(x: side * 0.33, y: side * 0.36)
    let arrowEnd = CGPoint(x: side * 0.68, y: side * 0.56)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.98))
    context.setLineWidth(max(2, side * 0.065))
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.move(to: arrowStart)
    context.addLine(to: arrowEnd)
    context.strokePath()

    let arrowHeadSize = side * 0.115
    let arrowHead = CGMutablePath()
    arrowHead.move(to: CGPoint(x: arrowEnd.x - arrowHeadSize * 0.9, y: arrowEnd.y + arrowHeadSize * 0.95))
    arrowHead.addLine(to: arrowEnd)
    arrowHead.addLine(to: CGPoint(x: arrowEnd.x - arrowHeadSize * 0.15, y: arrowEnd.y - arrowHeadSize * 1.05))
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.98))
    context.setLineWidth(max(2, side * 0.065))
    context.addPath(arrowHead)
    context.strokePath()

    return context.makeImage()
}
