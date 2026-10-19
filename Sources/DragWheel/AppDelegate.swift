import AppKit
import ServiceManagement
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate {
    private var statusItem: NSStatusItem!
    private let watcher = DragWatcher()
    private let radial = RadialMenuController()
    private let recorder = KeyRecorder()
    private let queue = DispatchQueue(label: "DragWheel.conversions", qos: .userInitiated)   // serial
    private var trigger = TriggerKey.current
    private var activeJobs = 0 { didSet { updateIcon() } }

    private var placeNextToOriginal: Bool {
        get { UserDefaults.standard.bool(forKey: "placeNextToOriginal") }
        set { UserDefaults.standard.set(newValue, forKey: "placeNextToOriginal") }
    }

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["placeNextToOriginal": true])

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
        updateIcon()

        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        watcher.isTriggerHeld = { [weak self] in self?.trigger.isHeld ?? false }
        watcher.onTrigger = { [weak self] point, files in self?.presentWheel(at: point, files: files) }
        watcher.onMouseUp = { [weak self] in self?.radial.hideAfterDrop() }
        radial.onChoose = { [weak self] format, files in self?.convert(files, to: format) }
        watcher.start()

        if !UserDefaults.standard.bool(forKey: "welcomed") {
            UserDefaults.standard.set(true, forKey: "welcomed")
            Notifier.post(title: "DragWheel is running",
                          body: "Hold ⇧ Shift while dragging a file to open the conversion wheel. Settings live in the menu bar.")
        }
    }

    // MARK: Wheel

    private func presentWheel(at point: NSPoint, files: [URL]) {
        let usable = files.filter { Formats.classify($0) != nil }
        guard let first = usable.first else { return }

        var targets = Formats.targets(for: first)
        for file in usable.dropFirst() {
            let t = Set(Formats.targets(for: file))
            targets = targets.filter { t.contains($0) }
        }
        guard !targets.isEmpty else { return }

        let items = targets.map { format -> RadialItem in
            let missing = usable.lazy.compactMap { Converter.missingRequirement(for: $0, to: format) }.first
            return RadialItem(format: format, enabled: missing == nil, note: missing.map { "needs \($0)" })
        }
        let label = usable.count == 1 ? (Formats.classify(first)?.format ?? "") : "\(usable.count) files"
        radial.show(at: point, files: usable, items: items, sourceLabel: label)
    }

    private func convert(_ files: [URL], to format: String) {
        for file in files {
            activeJobs += 1
            queue.async {
                let result = Result { try Converter.convert(file, to: format) }
                DispatchQueue.main.async {
                    self.activeJobs -= 1
                    switch result {
                    case .success(let output):
                        if self.placeNextToOriginal { FinderPlacement.place(output, nextTo: file) }
                    case .failure(let error):
                        Notifier.post(title: "Couldn't convert \(file.lastPathComponent)",
                                      body: error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: Menu bar

    private func updateIcon() {
        let busy = activeJobs > 0
        let image = NSImage(systemSymbolName: busy ? "arrow.triangle.2.circlepath" : "circle.circle",
                            accessibilityDescription: "DragWheel")
        image?.isTemplate = true
        statusItem?.button?.image = image
        statusItem?.button?.toolTip = busy ? "Converting \(activeJobs)…" : "DragWheel"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(disabled("DragWheel"))
        menu.addItem(disabled("Hold \(trigger.displayName) while dragging a file"))
        if activeJobs > 0 { menu.addItem(disabled("Converting \(activeJobs) file\(activeJobs == 1 ? "" : "s")…")) }
        menu.addItem(.separator())

        // Trigger key
        let triggerMenu = NSMenu()
        triggerMenu.autoenablesItems = false
        for option in TriggerKey.presets {
            triggerMenu.addItem(ClosureMenuItem(option.displayName, state: option == trigger ? .on : .off) { [weak self] in
                self?.setTrigger(option)
            })
        }
        triggerMenu.addItem(.separator())
        var customTitle = "Custom Key…"
        var customOn = false
        if case .key(_, let name) = trigger { customTitle = "Custom: \(name) (change…)"; customOn = true }
        triggerMenu.addItem(ClosureMenuItem(customTitle, state: customOn ? .on : .off) { [weak self] in
            self?.recorder.begin { key in if let key { self?.setTrigger(key) } }
        })
        let triggerItem = NSMenuItem(title: "Trigger Key", action: nil, keyEquivalent: "")
        triggerItem.submenu = triggerMenu
        menu.addItem(triggerItem)

        menu.addItem(ClosureMenuItem("Place Converted File Next to Original",
                                     state: placeNextToOriginal ? .on : .off) { [weak self] in
            self?.placeNextToOriginal.toggle()
        })

        let loginOn = SMAppService.mainApp.status == .enabled
        menu.addItem(ClosureMenuItem("Launch at Login", state: loginOn ? .on : .off) {
            do {
                if loginOn { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() }
            } catch {
                Notifier.post(title: "Launch at Login", body: error.localizedDescription)
            }
        })

        // Helper tools
        let toolsMenu = NSMenu()
        toolsMenu.autoenablesItems = false
        let missing = Tool.allCases.filter { $0.path == nil }
        for tool in Tool.allCases {
            let ok = tool.path != nil
            toolsMenu.addItem(disabled("\(ok ? "✓" : "✗")  \(tool.displayName) — \(tool.usedFor)"))
        }
        toolsMenu.addItem(.separator())
        if missing.isEmpty {
            toolsMenu.addItem(disabled("All helpers installed"))
        } else {
            toolsMenu.addItem(ClosureMenuItem("Copy Homebrew Install Command") {
                let cmd = missing.map(\.brewInstall).joined(separator: " && ")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(cmd, forType: .string)
            })
        }
        let toolsItem = NSMenuItem(title: "Helper Tools", action: nil, keyEquivalent: "")
        toolsItem.submenu = toolsMenu
        menu.addItem(toolsItem)

        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit DragWheel", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func setTrigger(_ key: TriggerKey) {
        trigger = key
        TriggerKey.current = key
    }

    // Show notifications even though we're a menu bar app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
