import CoreGraphics

enum PanelPlacementEngine {
    static func frame(
        panelSize: CGSize,
        mouseLocation: CGPoint,
        visibleFrame: CGRect,
        gap: CGFloat = 12
    ) -> CGRect {
        var x = mouseLocation.x + gap
        if x + panelSize.width > visibleFrame.maxX {
            x = mouseLocation.x - panelSize.width - gap
        }

        var y = mouseLocation.y - panelSize.height - gap
        if y < visibleFrame.minY {
            y = mouseLocation.y + gap
        }

        x = min(max(x, visibleFrame.minX), visibleFrame.maxX - panelSize.width)
        y = min(max(y, visibleFrame.minY), visibleFrame.maxY - panelSize.height)

        return CGRect(origin: CGPoint(x: x, y: y), size: panelSize).integral
    }
}
