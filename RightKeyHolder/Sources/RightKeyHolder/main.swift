import AppKit
import ApplicationServices

private let rightArrowKeyCode: CGKeyCode = 124

private enum RunMode: Int {
    case webSpeed = 0
    case keyHold = 1
}

private let defaultRunMode: RunMode = .keyHold

private enum BrowserKind {
    case safari
    case chromium
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var modePopup: NSPopUpButton!
    private var actionButton: NSButton!
    private var testButton: NSButton!
    private var statusLabel: NSTextField!
    private var permissionButton: NSButton!
    private var statusItem: NSStatusItem!
    private var repeatTimer: Timer?
    private var permissionTimer: Timer?
    private var isRunning = false
    private var activeMode: RunMode = defaultRunMode
    private var lastTargetApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        observeFrontmostApplication()
        createStatusItem()
        createPanel()
        refreshPermissionState()

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.refreshPermissionState()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopCurrentAction()
        permissionTimer?.invalidate()
    }

    private func observeFrontmostApplication() {
        let ownPid = ProcessInfo.processInfo.processIdentifier
        if let app = NSWorkspace.shared.frontmostApplication, app.processIdentifier != ownPid {
            lastTargetApp = app
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard
                let self,
                let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                app.processIdentifier != ownPid
            else { return }
            self.lastTargetApp = app
        }
    }

    private func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = defaultRunMode == .webSpeed ? "3x" : "→"
        statusItem.button?.toolTip = "右键长按助手"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "显示面板", action: #selector(showPanel), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "开始/停止", action: #selector(toggleCurrentAction), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func createPanel() {
        let visualView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 300, height: 178))
        visualView.material = .hudWindow
        visualView.blendingMode = .behindWindow
        visualView.state = .active

        let titleLabel = NSTextField(labelWithString: "右键长按助手")
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        modePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        modePopup.addItem(withTitle: "网页 3x")
        modePopup.addItem(withTitle: "按住右方向键")
        modePopup.selectItem(at: defaultRunMode.rawValue)
        modePopup.target = self
        modePopup.action = #selector(modeChanged)
        modePopup.translatesAutoresizingMaskIntoConstraints = false

        let initialActionTitle = defaultRunMode == .webSpeed ? "开始 3x" : "按住 →"
        actionButton = NSButton(title: initialActionTitle, target: self, action: #selector(toggleCurrentAction))
        actionButton.bezelStyle = .rounded
        actionButton.controlSize = .large
        actionButton.font = .systemFont(ofSize: 16, weight: .medium)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        let initialStatusText = defaultRunMode == .webSpeed ? "先切到视频页面，再点开始" : "未按住"
        statusLabel = NSTextField(labelWithString: initialStatusText)
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        testButton = NSButton(title: "点按 → 测试", target: self, action: #selector(testRightArrowTap))
        testButton.bezelStyle = .inline
        testButton.controlSize = .small
        testButton.font = .systemFont(ofSize: 12)
        testButton.translatesAutoresizingMaskIntoConstraints = false

        permissionButton = NSButton(title: "辅助功能权限", target: self, action: #selector(openAccessibilitySettings))
        permissionButton.bezelStyle = .inline
        permissionButton.controlSize = .small
        permissionButton.font = .systemFont(ofSize: 12)
        permissionButton.translatesAutoresizingMaskIntoConstraints = false

        visualView.addSubview(titleLabel)
        visualView.addSubview(modePopup)
        visualView.addSubview(actionButton)
        visualView.addSubview(statusLabel)
        visualView.addSubview(testButton)
        visualView.addSubview(permissionButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: visualView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: visualView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: visualView.trailingAnchor, constant: -16),

            modePopup.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            modePopup.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            modePopup.widthAnchor.constraint(equalToConstant: 174),

            actionButton.topAnchor.constraint(equalTo: modePopup.bottomAnchor, constant: 12),
            actionButton.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 154),
            actionButton.heightAnchor.constraint(equalToConstant: 36),

            statusLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: visualView.leadingAnchor, constant: 14),
            statusLabel.trailingAnchor.constraint(equalTo: visualView.trailingAnchor, constant: -14),

            testButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            testButton.trailingAnchor.constraint(equalTo: visualView.centerXAnchor, constant: -8),

            permissionButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            permissionButton.leadingAnchor.constraint(equalTo: visualView.centerXAnchor, constant: 8)
        ])

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 178),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "右键长按助手"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.contentView = visualView
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.orderFrontRegardless()
    }

    @objc private func showPanel() {
        panel.orderFrontRegardless()
    }

    @objc private func modeChanged() {
        stopCurrentAction()
        activeMode = RunMode(rawValue: modePopup.indexOfSelectedItem) ?? defaultRunMode
        updateIdleUI()
        refreshPermissionState()
    }

    @objc private func toggleCurrentAction() {
        isRunning ? stopCurrentAction() : startCurrentAction()
    }

    private func startCurrentAction() {
        activeMode = RunMode(rawValue: modePopup.indexOfSelectedItem) ?? defaultRunMode
        switch activeMode {
        case .webSpeed:
            startWebSpeed()
        case .keyHold:
            startKeyHold()
        }
    }

    private func stopCurrentAction() {
        switch activeMode {
        case .webSpeed:
            if isRunning {
                setWebVideoSpeed(rate: 1.0) { [weak self] ok, message in
                    guard let self else { return }
                    self.isRunning = false
                    self.updateIdleUI()
                    self.statusLabel.stringValue = ok ? "已恢复 1x" : message
                }
            }
        case .keyHold:
            stopKeyHold()
        }
    }

    private func startWebSpeed() {
        guard let target = lastTargetApp else {
            statusLabel.stringValue = "先打开视频所在窗口"
            return
        }
        guard browserKind(for: target.bundleIdentifier) != nil else {
            statusLabel.stringValue = "网页模式支持 Chrome/Edge/Brave/Safari"
            return
        }

        setWebVideoSpeed(rate: 3.0) { [weak self] ok, message in
            guard let self else { return }
            if ok {
                self.isRunning = true
                self.updateRunningUI()
                self.statusLabel.stringValue = "当前网页视频已设为 3x"
            } else {
                self.isRunning = false
                self.updateIdleUI()
                self.statusLabel.stringValue = message
            }
        }
    }

    private func setWebVideoSpeed(rate: Double, completion: @escaping (Bool, String) -> Void) {
        guard
            let target = lastTargetApp,
            let bundleIdentifier = target.bundleIdentifier,
            let kind = browserKind(for: bundleIdentifier)
        else {
            completion(false, "当前窗口不是支持的浏览器")
            return
        }

        let js = javascriptForPlaybackRate(rate)
        let scriptSource: String
        switch kind {
        case .safari:
            scriptSource = """
            tell application id "\(bundleIdentifier)"
                if not (exists front window) then return "NO_WINDOW"
                do JavaScript \(appleScriptString(js)) in current tab of front window
            end tell
            """
        case .chromium:
            scriptSource = """
            tell application id "\(bundleIdentifier)"
                if not (exists front window) then return "NO_WINDOW"
                execute active tab of front window javascript \(appleScriptString(js))
            end tell
            """
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            let result = NSAppleScript(source: scriptSource)?.executeAndReturnError(&error)
            let message: String
            let ok: Bool

            if let error {
                ok = false
                message = self.describeAppleScriptError(error)
            } else {
                let output = result?.stringValue ?? ""
                ok = output.hasPrefix("OK")
                if output == "NO_VIDEO" {
                    message = "当前页面没有找到视频"
                } else if output == "NO_WINDOW" {
                    message = "浏览器没有可用窗口"
                } else {
                    message = ok ? output : "浏览器没有返回成功状态"
                }
            }

            DispatchQueue.main.async {
                completion(ok, message)
            }
        }
    }

    private func javascriptForPlaybackRate(_ rate: Double) -> String {
        let rateString = String(format: "%.2f", rate)
        return """
        (() => {
          const videos = Array.from(document.querySelectorAll('video'));
          const video = videos.find(v => !v.paused && v.readyState > 0) || videos.find(v => v.readyState > 0) || videos[0];
          if (!video) return 'NO_VIDEO';
          if (\(rateString) !== 1.00) {
            window.__rightKeyHolderOriginalRate = video.playbackRate || 1;
            video.defaultPlaybackRate = \(rateString);
            video.playbackRate = \(rateString);
            return 'OK 3x';
          }
          const original = window.__rightKeyHolderOriginalRate || 1;
          video.defaultPlaybackRate = original;
          video.playbackRate = original;
          window.__rightKeyHolderOriginalRate = null;
          return 'OK 1x';
        })()
        """
    }

    private func browserKind(for bundleIdentifier: String?) -> BrowserKind? {
        guard let bundleIdentifier else { return nil }

        if bundleIdentifier == "com.apple.Safari" {
            return .safari
        }

        let chromiumBundleIdentifiers: Set<String> = [
            "com.google.Chrome",
            "com.google.Chrome.canary",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.vivaldi.Vivaldi",
            "com.operasoftware.Opera",
            "com.operasoftware.OperaGX",
            "company.thebrowser.Browser"
        ]

        return chromiumBundleIdentifiers.contains(bundleIdentifier) ? .chromium : nil
    }

    private func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private func describeAppleScriptError(_ error: NSDictionary) -> String {
        let message = error[NSAppleScript.errorMessage] as? String
        let number = error[NSAppleScript.errorNumber] as? NSNumber

        if let number, number.intValue == -1743 {
            return "请允许本工具控制浏览器"
        }

        if let message, !message.isEmpty {
            return message
        }

        return "浏览器控制失败"
    }

    private func startKeyHold() {
        guard accessibilityTrusted(prompt: false) else {
            statusLabel.stringValue = accessibilityHelpText()
            return
        }

        isRunning = true
        updateRunningUI()
        activateTargetIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self, self.isRunning, self.activeMode == .keyHold else { return }
            self.postRightArrow(keyDown: true, autorepeat: false)
            self.repeatTimer?.invalidate()
            self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                guard let self, self.isRunning, self.activeMode == .keyHold else { return }
                self.postRightArrow(keyDown: true, autorepeat: true)
            }
        }
    }

    private func stopKeyHold() {
        guard isRunning || repeatTimer != nil else { return }

        repeatTimer?.invalidate()
        repeatTimer = nil
        isRunning = false
        updateIdleUI()

        activateTargetIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.postRightArrow(keyDown: false, autorepeat: false)
        }
    }

    @objc private func testRightArrowTap() {
        guard accessibilityTrusted(prompt: false) else {
            statusLabel.stringValue = accessibilityHelpText()
            return
        }

        activateTargetIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.postRightArrow(keyDown: true, autorepeat: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { [weak self] in
                self?.postRightArrow(keyDown: false, autorepeat: false)
                self?.statusLabel.stringValue = "已点按一次右方向键"
            }
        }
    }

    private func updateRunningUI() {
        switch activeMode {
        case .webSpeed:
            actionButton.title = "恢复 1x"
            statusItem.button?.title = "3x●"
        case .keyHold:
            actionButton.title = "松开 →"
            statusItem.button?.title = "→●"
            statusLabel.stringValue = "右方向键按住中"
        }
    }

    private func updateIdleUI() {
        switch activeMode {
        case .webSpeed:
            actionButton.title = "开始 3x"
            statusItem.button?.title = "3x"
            statusLabel.stringValue = "先切到视频页面，再点开始"
        case .keyHold:
            actionButton.title = "按住 →"
            statusItem.button?.title = "→"
            statusLabel.stringValue = "未按住"
        }
    }

    private func activateTargetIfNeeded() {
        guard
            let target = lastTargetApp,
            !target.isTerminated,
            target.processIdentifier != ProcessInfo.processInfo.processIdentifier
        else { return }

        target.activate(options: [])
    }

    private func postRightArrow(keyDown: Bool, autorepeat: Bool) {
        guard let event = CGEvent(
            keyboardEventSource: CGEventSource(stateID: .hidSystemState),
            virtualKey: rightArrowKeyCode,
            keyDown: keyDown
        ) else { return }

        event.flags = []
        if autorepeat {
            event.setIntegerValueField(.keyboardEventAutorepeat, value: 1)
        }

        if let pid = lastTargetApp?.processIdentifier {
            event.postToPid(pid)
        }
        event.post(tap: .cgSessionEventTap)
    }

    private func refreshPermissionState() {
        let trusted = accessibilityTrusted(prompt: false)
        permissionButton.isHidden = trusted
        testButton.isHidden = false

        if activeMode == .keyHold, !trusted, !isRunning {
            statusLabel.stringValue = accessibilityHelpText()
        }
    }

    private func accessibilityHelpText() -> String {
        "辅助功能权限未生效，请点右侧权限按钮"
    }

    private func accessibilityTrusted(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @objc private func openAccessibilitySettings() {
        _ = accessibilityTrusted(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
