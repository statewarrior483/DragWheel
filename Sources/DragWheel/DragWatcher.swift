import AppKit

/// Watches for "a file drag is in progress AND the trigger key is held".
/// Uses polling (mouse buttons, modifier flags, drag pasteboard), so it needs
/// no Accessibility / Input Monitoring permission for modifier triggers.
final class DragWatcher {
    var isTriggerHeld: () -> Bool = { false }
    var onTrigger: ((NSPoint, [URL]) -> Void)?
    var onMouseUp: (() -> Void)?

    private let dragPasteboard = NSPasteboard(name: .drag)
    private var timer: Timer?
    private var mouseWasDown = false
    private var baselineChangeCount = 0
    private var dragFiles: [URL]?
    private var firedThisDrag = false

    func start() {
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let down = (NSEvent.pressedMouseButtons & 1) != 0

        guard down else {
            if mouseWasDown { onMouseUp?() }
            mouseWasDown = false
            dragFiles = nil
            firedThisDrag = false
            return
        }

        if !mouseWasDown {
            // Fresh press: remember the pasteboard state; a drag will bump it.
            mouseWasDown = true
            baselineChangeCount = dragPasteboard.changeCount
            return
        }
        if firedThisDrag { return }

        if dragFiles == nil, dragPasteboard.changeCount != baselineChangeCount {
            let urls = dragPasteboard.readObjects(forClasses: [NSURL.self],
                                                  options: [.urlReadingFileURLsOnly: true]) as? [URL]
            dragFiles = urls ?? []
        }
        guard let files = dragFiles, !files.isEmpty else { return }

        if isTriggerHeld() {
            firedThisDrag = true
            onTrigger?(NSEvent.mouseLocation, files)
        }
    }
}
