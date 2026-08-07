import SwiftUI

/// AppKit tracking area so hover also works while the quick-nav panel is a
/// non-activating panel that never becomes key (SwiftUI's onHover does not
/// fire reliably in that state).
struct HoverTrackingView: NSViewRepresentable {
    let isEnabled: Bool
    let onHover: (Bool) -> Void

    func makeNSView(context: Context) -> HoverTrackingNSView {
        let view = HoverTrackingNSView()
        view.onHover = onHover
        return view
    }

    func updateNSView(_ nsView: HoverTrackingNSView, context: Context) {
        nsView.onHover = onHover
    }
}

final class HoverTrackingNSView: NSView {
    var onHover: ((Bool) -> Void)?
    private var isHovering = false

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let options: NSTrackingArea.Options = [
            .activeAlways,
            .mouseEnteredAndExited,
            .mouseMoved,
            .inVisibleRect
        ]
        addTrackingArea(NSTrackingArea(rect: .zero, options: options, owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        guard !isHovering else { return }
        isHovering = true
        onHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        guard isHovering else { return }
        isHovering = false
        onHover?(false)
    }
}

struct QuickNavPathView: View {
    let directoryURL: URL
    let showFullPathOnHover: Bool
    let onNavigate: (URL) -> Void

    @State private var isHovering = false
    @State private var copiedPath = false
    @State private var copyFeedbackTask: Task<Void, Never>?

    private var display: FolderPathDisplay {
        FolderPathDisplay(url: directoryURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "house")
                    .imageScale(.small)
                if copiedPath {
                    Label("已复制", systemImage: "checkmark")
                        .foregroundStyle(.green)
                } else {
                    Text(isHovering ? display.fullPath : display.compactLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .contentShape(Rectangle())
            .onTapGesture(perform: copyCurrentPath)

            if isHovering && showFullPathOnHover {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(display.components) { component in
                            Button(component.label) {
                                onNavigate(component.url)
                            }
                            .buttonStyle(.link)
                            if component.id != display.components.last?.id {
                                Text("›")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .font(.caption2)
                }
                .padding(.leading, 14)
                .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .background(
            HoverTrackingView(isEnabled: showFullPathOnHover) { hovering in
                guard showFullPathOnHover else { return }
                withAnimation(.easeInOut(duration: 0.14)) {
                    isHovering = hovering
                }
            }
        )
    }

    private func copyCurrentPath() {
        QuickNavPathCopyService.copy(display.fullPath)
        copyFeedbackTask?.cancel()
        withAnimation(.easeOut(duration: 0.12)) {
            copiedPath = true
        }
        copyFeedbackTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.15)) {
                    copiedPath = false
                }
            }
        }
    }
}
