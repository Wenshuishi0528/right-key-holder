import AppKit
import ApplicationServices

private let rightArrowKeyCode: CGKeyCode = 124

private enum RunMode: Int {
    case webSpeed = 0
    case keyHold = 1
}

private let defaultRunMode: RunMode = .keyHold
private let languageDefaultsKey = "SelectedLanguage"

private enum BrowserKind {
    case safari
    case chromium
}

private enum AppLanguage: Int {
    case zh = 0
    case en = 1
}

private let localizedStrings: [String: (zh: String, en: String)] = [
    "appTitle": ("右键长按助手", "Right Key Holder"),
    "showPanel": ("显示面板", "Show Panel"),
    "startStop": ("开始/停止", "Start/Stop"),
    "quit": ("退出", "Quit"),
    "modeWeb": ("网页 3x", "Web 3x"),
    "modeKeyHold": ("按住右方向键", "Hold Right Arrow"),
    "startWeb": ("开始 3x", "Start 3x"),
    "restoreWeb": ("恢复 1x", "Restore 1x"),
    "holdKey": ("按住 →", "Hold →"),
    "releaseKey": ("松开 →", "Release →"),
    "testTap": ("点按 → 测试", "Tap → Test"),
    "permission": ("辅助功能权限", "Accessibility"),
    "webIdle": ("先切到视频页面，再点开始", "Focus a video page, then start"),
    "keyIdle": ("未按住", "Not holding"),
    "keyHolding": ("右方向键按住中", "Holding right arrow"),
    "restored1x": ("已恢复 1x", "Restored 1x"),
    "openVideoWindow": ("先打开视频所在窗口", "Open the video window first"),
    "browserUnsupported": ("网页模式支持 Chrome/Edge/Brave/Safari", "Use Chrome/Edge/Brave/Safari"),
    "web3xSet": ("当前网页视频已设为 3x", "Current web video is set to 3x"),
    "notBrowser": ("当前窗口不是支持的浏览器", "Unsupported browser"),
    "noVideo": ("当前页面没有找到视频", "No video found on this page"),
    "noWindow": ("浏览器没有可用窗口", "Browser has no available window"),
    "browserNoSuccess": ("浏览器没有返回成功状态", "Browser did not confirm"),
    "allowBrowserControl": ("请允许本工具控制浏览器", "Allow this tool to control the browser"),
    "browserControlFailed": ("浏览器控制失败", "Browser control failed"),
    "testTapped": ("已点按一次右方向键", "Tapped right arrow once"),
    "accessibilityHelp": ("辅助功能权限未生效，请点右侧权限按钮", "Use Accessibility button")
]

private func localizedText(_ key: String, language: AppLanguage) -> String {
    guard let value = localizedStrings[key] else { return key }
    return language == .zh ? value.zh : value.en
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var iconImageView: NSImageView!
    private var titleLabel: NSTextField!
    private var languagePopup: NSPopUpButton!
    private var modePopup: NSPopUpButton!
    private var actionButton: NSButton!
    private var testButton: NSButton!
    private var statusLabel: NSTextField!
    private var permissionButton: NSButton!
    private var statusItem: NSStatusItem!
    private var showPanelMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!
    private var repeatTimer: Timer?
    private var permissionTimer: Timer?
    private var isRunning = false
    private var activeMode: RunMode = defaultRunMode
    private var currentLanguage: AppLanguage = AppLanguage(
        rawValue: UserDefaults.standard.integer(forKey: languageDefaultsKey)
    ) ?? .zh
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
        statusItem.button?.toolTip = t("appTitle")

        let menu = NSMenu()
        showPanelMenuItem = NSMenuItem(title: t("showPanel"), action: #selector(showPanel), keyEquivalent: "")
        toggleMenuItem = NSMenuItem(title: t("startStop"), action: #selector(toggleCurrentAction), keyEquivalent: "")
        quitMenuItem = NSMenuItem(title: t("quit"), action: #selector(quit), keyEquivalent: "q")
        menu.addItem(showPanelMenuItem)
        menu.addItem(toggleMenuItem)
        menu.addItem(.separator())
        menu.addItem(quitMenuItem)
        statusItem.menu = menu
    }

    private func createPanel() {
        let visualView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 330, height: 270))
        visualView.material = .hudWindow
        visualView.blendingMode = .behindWindow
        visualView.state = .active

        iconImageView = NSImageView()
        iconImageView.image = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
            .flatMap { NSImage(contentsOf: $0) } ?? NSApp.applicationIconImage
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        iconImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel = NSTextField(labelWithString: t("appTitle"))
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        languagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        languagePopup.addItem(withTitle: "中文")
        languagePopup.addItem(withTitle: "English")
        languagePopup.selectItem(at: currentLanguage.rawValue)
        languagePopup.target = self
        languagePopup.action = #selector(languageChanged)
        languagePopup.translatesAutoresizingMaskIntoConstraints = false

        modePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        modePopup.addItem(withTitle: t("modeWeb"))
        modePopup.addItem(withTitle: t("modeKeyHold"))
        modePopup.selectItem(at: defaultRunMode.rawValue)
        modePopup.target = self
        modePopup.action = #selector(modeChanged)
        modePopup.translatesAutoresizingMaskIntoConstraints = false

        let initialActionTitle = defaultRunMode == .webSpeed ? t("startWeb") : t("holdKey")
        actionButton = NSButton(title: initialActionTitle, target: self, action: #selector(toggleCurrentAction))
        actionButton.bezelStyle = .rounded
        actionButton.controlSize = .large
        actionButton.font = .systemFont(ofSize: 16, weight: .medium)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        let initialStatusText = defaultRunMode == .webSpeed ? t("webIdle") : t("keyIdle")
        statusLabel = NSTextField(labelWithString: initialStatusText)
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        testButton = NSButton(title: t("testTap"), target: self, action: #selector(testRightArrowTap))
        testButton.bezelStyle = .inline
        testButton.controlSize = .small
        testButton.font = .systemFont(ofSize: 12)
        testButton.translatesAutoresizingMaskIntoConstraints = false

        permissionButton = NSButton(title: t("permission"), target: self, action: #selector(openAccessibilitySettings))
        permissionButton.bezelStyle = .inline
        permissionButton.controlSize = .small
        permissionButton.font = .systemFont(ofSize: 12)
        permissionButton.translatesAutoresizingMaskIntoConstraints = false

        visualView.addSubview(iconImageView)
        visualView.addSubview(titleLabel)
        visualView.addSubview(languagePopup)
        visualView.addSubview(modePopup)
        visualView.addSubview(actionButton)
        visualView.addSubview(statusLabel)
        visualView.addSubview(testButton)
        visualView.addSubview(permissionButton)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: visualView.topAnchor, constant: 16),
            iconImageView.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: visualView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: visualView.trailingAnchor, constant: -16),

            languagePopup.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            languagePopup.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            languagePopup.widthAnchor.constraint(equalToConstant: 174),

            modePopup.topAnchor.constraint(equalTo: languagePopup.bottomAnchor, constant: 8),
            modePopup.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            modePopup.widthAnchor.constraint(equalToConstant: 190),

            actionButton.topAnchor.constraint(equalTo: modePopup.bottomAnchor, constant: 12),
            actionButton.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 170),
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
            contentRect: NSRect(x: 0, y: 0, width: 330, height: 270),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = t("appTitle")
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

    @objc private func languageChanged() {
        currentLanguage = AppLanguage(rawValue: languagePopup.indexOfSelectedItem) ?? .zh
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageDefaultsKey)
        applyLanguage()
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
                    self.statusLabel.stringValue = ok ? self.t("restored1x") : message
                }
            }
        case .keyHold:
            stopKeyHold()
        }
    }

    private func startWebSpeed() {
        guard let target = lastTargetApp else {
            statusLabel.stringValue = t("openVideoWindow")
            return
        }
        guard browserKind(for: target.bundleIdentifier) != nil else {
            statusLabel.stringValue = t("browserUnsupported")
            return
        }

        setWebVideoSpeed(rate: 3.0) { [weak self] ok, message in
            guard let self else { return }
            if ok {
                self.isRunning = true
                self.updateRunningUI()
                self.statusLabel.stringValue = self.t("web3xSet")
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
            completion(false, t("notBrowser"))
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
                    message = self.t("noVideo")
                } else if output == "NO_WINDOW" {
                    message = self.t("noWindow")
                } else {
                    message = ok ? output : self.t("browserNoSuccess")
                }
            }

            DispatchQueue.main.async {
                completion(ok, message)
            }
        }
    }

    private func javascriptForPlaybackRate(_ rate: Double) -> String {
        let rateString = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), rate)
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
            return t("allowBrowserControl")
        }

        if let message, !message.isEmpty {
            return message
        }

        return t("browserControlFailed")
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
                self?.statusLabel.stringValue = self?.t("testTapped") ?? ""
            }
        }
    }

    private func updateRunningUI() {
        switch activeMode {
        case .webSpeed:
            actionButton.title = t("restoreWeb")
            statusItem.button?.title = "3x●"
            statusLabel.stringValue = t("web3xSet")
        case .keyHold:
            actionButton.title = t("releaseKey")
            statusItem.button?.title = "→●"
            statusLabel.stringValue = t("keyHolding")
        }
    }

    private func updateIdleUI() {
        switch activeMode {
        case .webSpeed:
            actionButton.title = t("startWeb")
            statusItem.button?.title = "3x"
            statusLabel.stringValue = t("webIdle")
        case .keyHold:
            actionButton.title = t("holdKey")
            statusItem.button?.title = "→"
            statusLabel.stringValue = t("keyIdle")
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
        t("accessibilityHelp")
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

    private func applyLanguage() {
        titleLabel.stringValue = t("appTitle")
        panel.title = t("appTitle")
        statusItem.button?.toolTip = t("appTitle")
        showPanelMenuItem.title = t("showPanel")
        toggleMenuItem.title = t("startStop")
        quitMenuItem.title = t("quit")
        modePopup.item(at: RunMode.webSpeed.rawValue)?.title = t("modeWeb")
        modePopup.item(at: RunMode.keyHold.rawValue)?.title = t("modeKeyHold")
        testButton.title = t("testTap")
        permissionButton.title = t("permission")

        if isRunning {
            updateRunningUI()
        } else {
            updateIdleUI()
        }
        refreshPermissionState()
    }

    private func t(_ key: String) -> String {
        localizedText(key, language: currentLanguage)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
