import AppKit
import UserNotifications

/// Asks Finder to put the new item right beside the original (icon views only;
/// list/column views and auto-arranged folders sort by name, which keeps them adjacent anyway).
enum FinderPlacement {
    static func place(_ item: URL, nextTo original: URL) {
        func esc(_ s: String) -> String {
            s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        }
        let script = """
        tell application "Finder"
            set srcItem to item ((POSIX file "\(esc(original.path))") as alias)
            set dstItem to item ((POSIX file "\(esc(item.path))") as alias)
            set c to container of srcItem
            try
                update c
            end try
            set gap to 110
            try
                if (POSIX path of (c as alias)) is (POSIX path of (path to desktop folder)) then
                    set s to icon size of icon view options of window of desktop
                else
                    set s to icon size of icon view options of container window of c
                end if
                set gap to s + 46
                if gap < 110 then set gap to 110
            end try
            set p to position of srcItem
            set position of dstItem to {(item 1 of p) + gap, item 2 of p}
        end tell
        """
        // Short delay so Finder has noticed the new file.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            if let error { NSLog("DragWheel placement: \(error)") }
        }
    }
}

enum Notifier {
    static func post(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}

/// NSMenuItem that runs a closure.
final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, key: String = "", state: NSControl.StateValue = .off, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: key)
        self.target = self
        self.state = state
    }
    required init(coder: NSCoder) { fatalError("init(coder:) not used") }

    @objc private func fire() { handler() }
}
