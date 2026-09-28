import CoreGraphics

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
let panel = CGSize(width: 292, height: 286)

let cases: [(name: String, mouse: CGPoint, visibleFrame: CGRect, origin: CGPoint)] = [
    ("center", CGPoint(x: 700, y: 450), screen, CGPoint(x: 554, y: 307)),
    ("fractional cursor", CGPoint(x: 715.25, y: 470.75), screen, CGPoint(x: 569.25, y: 327.75)),
    ("bottom left", CGPoint(x: 5, y: 5), screen, CGPoint(x: 0, y: 0)),
    ("bottom right", CGPoint(x: 1435, y: 5), screen, CGPoint(x: 1148, y: 0)),
    ("top left", CGPoint(x: 5, y: 895), screen, CGPoint(x: 0, y: 614)),
    ("top right", CGPoint(x: 1435, y: 895), screen, CGPoint(x: 1148, y: 614)),
    (
        "display left of primary",
        CGPoint(x: -750, y: 500),
        CGRect(x: -1440, y: 40, width: 1440, height: 860),
        CGPoint(x: -896, y: 357)
    ),
    (
        "display left of primary bottom edge",
        CGPoint(x: -10, y: 45),
        CGRect(x: -1440, y: 40, width: 1440, height: 860),
        CGPoint(x: -292, y: 40)
    )
]

for testCase in cases {
    let frame = PanelPlacementEngine.frame(
        panelSize: panel,
        mouseLocation: testCase.mouse,
        visibleFrame: testCase.visibleFrame
    )
    expect(frame.origin == testCase.origin, "\(testCase.name): card must center on cursor, clamping only at screen edges")
    expect(frame.size == panel, "\(testCase.name): placement must preserve the exact card size")
    expect(testCase.visibleFrame.contains(frame), "\(testCase.name): card must remain in the visible screen frame")
}

print("panel placement smoke test passed")
