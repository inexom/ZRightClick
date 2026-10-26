import AppKit
import SwiftUI
import os

// AppKit owns the lifecycle so receiving a Finder URL never creates a settings
// window. SwiftUI is used only to render the existing settings content.
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let log = Logger(subsystem: "com.inexom.zrightclick", category: "Lifecycle")
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var settingsWindowFrame: NSRect?
    private var isTerminating = false

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) {
            application.run()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = TerminalSettings.shared
        MenuSettings.shared.publish()
        configureApplicationMenu()
        configureStatusItem()
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: L10n.changed, object: nil)
        log.info("应用已启动，菜单栏入口已创建")
    }

    // A normal launch (Finder / Launchpad / open -a) opens settings. A launch
    // carrying a URL goes to application(_:open:) instead and stays accessory.
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        showSettings()
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.absoluteString == "zrightclick://settings" {
                MenuSettings.shared.selectedTab = .types
                showSettings()
            } else {
                FileActionController.shared.receive(url)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        isTerminating = true
        return .terminateNow
    }

    func windowWillClose(_ notification: Notification) {
        guard !isTerminating, let window = notification.object as? NSWindow, window === settingsWindow else { return }
        settingsWindowFrame = window.frame
        ExtensionSetup.shared.stop()
        window.delegate = nil
        settingsWindow = nil
        // Keep the closing window alive until AppKit finishes this close event,
        // then detach its SwiftUI tree. A reopen creates a new window, so this
        // deferred cleanup can never detach the newly opened settings view.
        DispatchQueue.main.async {
            window.contentView = nil
        }
        // Authorization panels and queued Finder actions have independent
        // lifetimes; only the settings UI is discarded here.
        NSApp.setActivationPolicy(.accessory)
        log.info("主窗口已关闭，设置界面已安排释放，Dock 已隐藏，应用继续运行")
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let hostingView = NSHostingView(rootView: ContentView())
            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: NSSize(width: 660, height: 650)),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "ZRightClick"
            window.contentMinSize = NSSize(width: 620, height: 540)
            window.identifier = NSUserInterfaceItemIdentifier("ZRightClick.settings")
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = hostingView
            if let frame = settingsWindowFrame {
                window.setFrame(frame, display: false)
            } else {
                window.center()
            }
            settingsWindow = window
        }
        // Showing a management window opts back into normal Dock behavior;
        // closing it returns to accessory mode without destroying the process.
        NSApp.setActivationPolicy(.regular)
        settingsWindow?.deminiaturize(nil)
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        log.info("主窗口已打开，Dock 已显示")
    }

    @objc private func quit() {
        log.info("从菜单退出应用")
        NSApp.terminate(nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.autosaveName = "ZRightClick.status"
        let image = NSImage(systemSymbolName: "cursorarrow.click", accessibilityDescription: "ZRightClick")
        image?.isTemplate = true
        item.button?.image = image
        item.button?.toolTip = "ZRightClick"
        item.button?.setAccessibilityLabel("ZRightClick")

        // NSStatusItem's standard menu supports both left and right clicks.
        let menu = NSMenu()
        let open = NSMenuItem(title: L10n.text("打开 ZRightClick"), action: #selector(showSettings), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())
        let exit = NSMenuItem(title: L10n.text("退出 ZRightClick"), action: #selector(quit), keyEquivalent: "q")
        exit.target = self
        menu.addItem(exit)
        item.menu = menu
        statusItem = item
    }

    @objc private func languageChanged() {
        configureApplicationMenu()
        statusItem?.menu?.items.first?.title = L10n.text("打开 ZRightClick")
        statusItem?.menu?.items.last?.title = L10n.text("退出 ZRightClick")
    }

    private func configureApplicationMenu() {
        let menu = NSMenu()
        let applicationItem = NSMenuItem()
        let applicationMenu = NSMenu(title: "ZRightClick")
        let quitItem = NSMenuItem(title: L10n.text("退出 ZRightClick"), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        applicationMenu.addItem(quitItem)
        applicationItem.submenu = applicationMenu
        menu.addItem(applicationItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: L10n.text("编辑"))
        editMenu.addItem(withTitle: L10n.text("剪切"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: L10n.text("拷贝"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: L10n.text("粘贴"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: L10n.text("全选"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        menu.addItem(editItem)

        let windowItem = NSMenuItem()
        let windowMenu = NSMenu(title: L10n.text("窗口"))
        windowMenu.addItem(withTitle: L10n.text("最小化"), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: L10n.text("关闭窗口"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = windowMenu
        menu.addItem(windowItem)
        NSApp.mainMenu = menu
        NSApp.windowsMenu = windowMenu
    }
}
