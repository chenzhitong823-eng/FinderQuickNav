import CoreGraphics

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
let panel = CGSize(width: 292, height: 286)

let centerFrame = PanelPlacementEngine.frame(
    panelSize: panel,
    mouseLocation: CGPoint(x: 700, y: 450),
    visibleFrame: screen
)
expect(screen.contains(centerFrame), "Centered placement must remain on screen")
expect(centerFrame.minX > 700, "Preferred placement should begin to the right of the cursor")

let edgeFrame = PanelPlacementEngine.frame(
    panelSize: panel,
    mouseLocation: CGPoint(x: 1435, y: 5),
    visibleFrame: screen
)
expect(screen.contains(edgeFrame), "Edge placement must be clamped on screen")
expect(edgeFrame.maxX <= screen.maxX, "Edge placement overflowed horizontally")
expect(edgeFrame.minY >= screen.minY, "Edge placement overflowed vertically")

print("panel placement smoke test passed")
