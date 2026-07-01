import AppKit
import ApplicationServices

private let rightArrowKeyCode: CGKeyCode = 124
private let spaceKeyCode: CGKeyCode = 49

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
    "holdKey": ("按住 →", "Hold →"),
    "releaseKey": ("松开 →", "Release →"),
    "playPauseVideo": ("开始/暂停", "Play/Pause"),
    "testTap": ("点按 → 测试", "Tap → Test"),
    "permission": ("辅助功能权限", "Accessibility"),
    "keyIdle": ("未按住", "Not holding"),
    "keyHolding": ("右方向键按住中", "Holding right arrow"),
    "openVideoWindow": ("先打开视频所在窗口", "Open the video window first"),
    "videoPaused": ("已暂停视频", "Video paused"),
    "videoPlaying": ("已开始播放", "Video playing"),
    "playPauseKeySent": ("已发送开始/暂停键", "Sent play/pause key"),
    "holdBehaviorNote": (
        "请先点击视频窗口，再点击本工具按钮。\nB站按住效果为视频三倍速。\nYouTube按住效果为视频快进。",
        "Click the video window first, then click this tool.\nBilibili hold: 3x video speed.\nYouTube hold: video fast-forward."
    ),
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

final class FilledButton: NSButton {
    var fillColor: NSColor = .controlAccentColor {
        didSet { needsDisplay = true }
    }

    var textColor: NSColor = .white {
        didSet { needsDisplay = true }
    }

    override var title: String {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        let color = isHighlighted ? (fillColor.blended(withFraction: 0.14, of: .black) ?? fillColor) : fillColor
        color.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8).fill()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium),
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        let attributedTitle = NSAttributedString(string: title, attributes: attributes)
        let titleSize = attributedTitle.size()
        let titleRect = NSRect(
            x: 8,
            y: (bounds.height - titleSize.height) / 2,
            width: bounds.width - 16,
            height: titleSize.height
        )
        attributedTitle.draw(in: titleRect)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: NSPanel!
    private var iconImageView: NSImageView!
    private var titleLabel: NSTextField!
    private var languagePopup: NSPopUpButton!
    private var actionButton: FilledButton!
    private var pauseButton: NSButton!
    private var testButton: NSButton!
    private var statusLabel: NSTextField!
    private var permissionButton: NSButton!
    private var behaviorNoteLabel: NSTextField!
    private var versionLabel: NSTextField!
    private var statusItem: NSStatusItem!
    private var showPanelMenuItem: NSMenuItem!
    private var toggleMenuItem: NSMenuItem!
    private var quitMenuItem: NSMenuItem!
    private var repeatTimer: Timer?
    private var permissionTimer: Timer?
    private var isRunning = false
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
        statusItem.button?.title = "→"
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
        let visualView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 330, height: 360))
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

        actionButton = FilledButton(title: t("holdKey"), target: self, action: #selector(toggleCurrentAction))
        actionButton.isBordered = false
        actionButton.fillColor = holdColor
        actionButton.textColor = .white
        actionButton.controlSize = .large
        actionButton.font = .systemFont(ofSize: 16, weight: .medium)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        pauseButton = NSButton(title: t("playPauseVideo"), target: self, action: #selector(playPauseVideo))
        pauseButton.bezelStyle = .rounded
        pauseButton.controlSize = .regular
        pauseButton.font = .systemFont(ofSize: 13, weight: .medium)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false

        statusLabel = NSTextField(labelWithString: t("keyIdle"))
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

        behaviorNoteLabel = NSTextField(labelWithString: t("holdBehaviorNote"))
        behaviorNoteLabel.font = .systemFont(ofSize: 11, weight: .regular)
        behaviorNoteLabel.textColor = .secondaryLabelColor
        behaviorNoteLabel.alignment = .center
        behaviorNoteLabel.maximumNumberOfLines = 3
        behaviorNoteLabel.lineBreakMode = .byTruncatingTail
        behaviorNoteLabel.translatesAutoresizingMaskIntoConstraints = false

        versionLabel = NSTextField(labelWithString: appVersionText())
        versionLabel.font = .systemFont(ofSize: 10, weight: .regular)
        versionLabel.textColor = .tertiaryLabelColor
        versionLabel.alignment = .right
        versionLabel.translatesAutoresizingMaskIntoConstraints = false

        visualView.addSubview(iconImageView)
        visualView.addSubview(titleLabel)
        visualView.addSubview(languagePopup)
        visualView.addSubview(actionButton)
        visualView.addSubview(pauseButton)
        visualView.addSubview(statusLabel)
        visualView.addSubview(testButton)
        visualView.addSubview(permissionButton)
        visualView.addSubview(behaviorNoteLabel)
        visualView.addSubview(versionLabel)

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

            actionButton.topAnchor.constraint(equalTo: languagePopup.bottomAnchor, constant: 20),
            actionButton.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 170),
            actionButton.heightAnchor.constraint(equalToConstant: 36),

            pauseButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 8),
            pauseButton.centerXAnchor.constraint(equalTo: visualView.centerXAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 170),
            pauseButton.heightAnchor.constraint(equalToConstant: 30),

            statusLabel.topAnchor.constraint(equalTo: pauseButton.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: visualView.leadingAnchor, constant: 14),
            statusLabel.trailingAnchor.constraint(equalTo: visualView.trailingAnchor, constant: -14),

            testButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            testButton.trailingAnchor.constraint(equalTo: visualView.centerXAnchor, constant: -8),

            permissionButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 5),
            permissionButton.leadingAnchor.constraint(equalTo: visualView.centerXAnchor, constant: 8),

            behaviorNoteLabel.leadingAnchor.constraint(equalTo: visualView.leadingAnchor, constant: 18),
            behaviorNoteLabel.trailingAnchor.constraint(equalTo: visualView.trailingAnchor, constant: -18),
            behaviorNoteLabel.bottomAnchor.constraint(equalTo: visualView.bottomAnchor, constant: -24),

            versionLabel.trailingAnchor.constraint(equalTo: visualView.trailingAnchor, constant: -10),
            versionLabel.bottomAnchor.constraint(equalTo: visualView.bottomAnchor, constant: -8)
        ])

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 330, height: 360),
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

    @objc private func languageChanged() {
        currentLanguage = AppLanguage(rawValue: languagePopup.indexOfSelectedItem) ?? .zh
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageDefaultsKey)
        applyLanguage()
    }

    @objc private func toggleCurrentAction() {
        isRunning ? stopCurrentAction() : startCurrentAction()
    }

    private func startCurrentAction() {
        startKeyHold()
    }

    private func stopCurrentAction() {
        stopKeyHold()
    }

    @objc private func playPauseVideo() {
        if isRunning {
            stopKeyHold()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                self?.performPlayPauseVideo()
            }
            return
        }

        performPlayPauseVideo()
    }

    private func performPlayPauseVideo() {
        guard let target = lastTargetApp else {
            statusLabel.stringValue = t("openVideoWindow")
            return
        }

        if browserKind(for: target.bundleIdentifier) != nil {
            toggleWebVideoPlayback { [weak self] ok, message in
                guard let self else { return }
                if ok {
                    self.statusLabel.stringValue = message
                } else if message == self.t("noVideo") || message == self.t("noWindow") {
                    self.statusLabel.stringValue = message
                } else {
                    self.playPauseWithSpaceKey(failureMessage: message)
                }
            }
            return
        }

        playPauseWithSpaceKey(failureMessage: nil)
    }

    private func toggleWebVideoPlayback(completion: @escaping (Bool, String) -> Void) {
        guard
            let target = lastTargetApp,
            let bundleIdentifier = target.bundleIdentifier,
            let kind = browserKind(for: bundleIdentifier)
        else {
            completion(false, t("notBrowser"))
            return
        }

        let js = """
        (() => {
          const videos = Array.from(document.querySelectorAll('video'));
          const video = videos.find(v => !v.paused && v.readyState > 0) || videos.find(v => v.readyState > 0) || videos[0];
          if (!video) return 'NO_VIDEO';
          if (video.paused) {
            const playResult = video.play();
            if (playResult && typeof playResult.catch === 'function') playResult.catch(() => {});
            return 'OK_PLAYING';
          }
          video.pause();
          return 'OK_PAUSED';
        })()
        """

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
                } else if output == "OK_PLAYING" {
                    message = self.t("videoPlaying")
                } else if output == "OK_PAUSED" {
                    message = self.t("videoPaused")
                } else {
                    message = ok ? output : self.t("browserNoSuccess")
                }
            }

            DispatchQueue.main.async {
                completion(ok, message)
            }
        }
    }

    private func playPauseWithSpaceKey(failureMessage: String?) {
        guard accessibilityTrusted(prompt: false) else {
            statusLabel.stringValue = failureMessage ?? accessibilityHelpText()
            return
        }

        activateTargetIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.postKey(spaceKeyCode, keyDown: true, autorepeat: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) { [weak self] in
                self?.postKey(spaceKeyCode, keyDown: false, autorepeat: false)
                self?.statusLabel.stringValue = self?.t("playPauseKeySent") ?? ""
            }
        }
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
            guard let self, self.isRunning else { return }
            self.postRightArrow(keyDown: true, autorepeat: false)
            self.repeatTimer?.invalidate()
            self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                guard let self, self.isRunning else { return }
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
        actionButton.title = t("releaseKey")
        actionButton.fillColor = releaseColor
        statusItem.button?.title = "→●"
        statusLabel.stringValue = t("keyHolding")
    }

    private func updateIdleUI() {
        actionButton.title = t("holdKey")
        actionButton.fillColor = holdColor
        statusItem.button?.title = "→"
        statusLabel.stringValue = t("keyIdle")
    }

    private var holdColor: NSColor {
        NSColor(calibratedRed: 0.18, green: 0.44, blue: 0.93, alpha: 1)
    }

    private var releaseColor: NSColor {
        NSColor(calibratedRed: 0.86, green: 0.20, blue: 0.16, alpha: 1)
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
        postKey(rightArrowKeyCode, keyDown: keyDown, autorepeat: autorepeat)
    }

    private func postKey(_ keyCode: CGKeyCode, keyDown: Bool, autorepeat: Bool) {
        guard let event = CGEvent(
            keyboardEventSource: CGEventSource(stateID: .hidSystemState),
            virtualKey: keyCode,
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

        if !trusted, !isRunning {
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
        pauseButton.title = t("playPauseVideo")
        testButton.title = t("testTap")
        permissionButton.title = t("permission")
        behaviorNoteLabel.stringValue = t("holdBehaviorNote")

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

    private func appVersionText() -> String {
        guard
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            !version.isEmpty
        else {
            return "made by Wenshuishi v dev"
        }

        return "made by Wenshuishi v\(version)"
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
