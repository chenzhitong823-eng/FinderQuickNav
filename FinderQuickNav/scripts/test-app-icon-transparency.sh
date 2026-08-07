#!/bin/zsh

set -euo pipefail

script_dir="${0:A:h}"
project_dir="${script_dir:h}"
icon_path="${1:-${project_dir}/App/Assets.xcassets/AppIcon.appiconset/icon_1024x1024.png}"

[[ -f "${icon_path}" ]]

swift - "${icon_path}" <<'SWIFT'
import AppKit
import Foundation

let iconURL = URL(fileURLWithPath: CommandLine.arguments[1])
guard let image = NSImage(contentsOf: iconURL),
      let bitmap = NSBitmapImageRep(data: image.tiffRepresentation ?? Data()) else {
    fputs("Unable to read app icon as RGBA bitmap: \(iconURL.path)\n", stderr)
    exit(1)
}

guard bitmap.pixelsWide == 1024, bitmap.pixelsHigh == 1024 else {
    fputs("Expected a 1024 × 1024 master app icon, got \(bitmap.pixelsWide) × \(bitmap.pixelsHigh).\n", stderr)
    exit(1)
}

func components(atX x: Int, y: Int) -> [Int] {
    var components = [Int](repeating: 0, count: 4)
    components.withUnsafeMutableBufferPointer { buffer in
        bitmap.getPixel(buffer.baseAddress!, atX: x, y: y)
    }
    return components
}

func alpha(atX x: Int, y: Int) -> UInt8 {
    UInt8(clamping: components(atX: x, y: y)[3])
}

let transparentCorners = [(0, 0), (1023, 0), (0, 1023), (1023, 1023)]
for (x, y) in transparentCorners where alpha(atX: x, y: y) > 1 {
    fputs("Expected transparent app-icon corner at (\(x), \(y)); found alpha \(alpha(atX: x, y: y)).\n", stderr)
    exit(1)
}

// The source's own rounded-square outline is fuller than a 210 pt radius.
// This point sits outside the visible artwork but was still showing the
// screenshot's checkerboard when the clipping curve was too shallow.
let transparentOutlineSamples = [(980, 100), (43, 100), (980, 923), (43, 923)]
for (x, y) in transparentOutlineSamples where alpha(atX: x, y: y) > 1 {
    fputs("Expected no baked screenshot background at outline sample (\(x), \(y)); found alpha \(alpha(atX: x, y: y)).\n", stderr)
    exit(1)
}

let rightEdgeColour = components(atX: 1000, y: 512)
let rightEdgeRGB = Array(rightEdgeColour.prefix(3))
if rightEdgeRGB.max()! - rightEdgeRGB.min()! < 12, rightEdgeRGB.min()! > 225 {
    fputs("Expected source artwork at the right edge, not the screenshot's white checkerboard; found RGBA \(rightEdgeColour).\n", stderr)
    exit(1)
}

let opaqueImageSamples = [(512, 0), (0, 512), (512, 512)]
for (x, y) in opaqueImageSamples where alpha(atX: x, y: y) < 250 {
    fputs("Expected visible app artwork at (\(x), \(y)); found alpha \(alpha(atX: x, y: y)).\n", stderr)
    exit(1)
}

print("app icon transparency test passed: true rounded-outline alpha")
SWIFT
