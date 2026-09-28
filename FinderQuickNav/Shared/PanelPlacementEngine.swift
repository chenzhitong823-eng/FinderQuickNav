import CoreGraphics

enum PanelPlacementEngine {
    static func frame(
        panelSize: CGSize,
        mouseLocation: CGPoint,
        visibleFrame: CGRect
    ) -> CGRect {
        let x = min(
            max(mouseLocation.x - panelSize.width / 2, visibleFrame.minX),
            visibleFrame.maxX - panelSize.width
        )
        let y = min(
            max(mouseLocation.y - panelSize.height / 2, visibleFrame.minY),
            visibleFrame.maxY - panelSize.height
        )

        return CGRect(origin: CGPoint(x: x, y: y), size: panelSize)
    }
}
