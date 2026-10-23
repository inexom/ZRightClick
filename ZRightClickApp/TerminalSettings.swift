import AppKit
import Combine

@MainActor
final class TerminalSettings: NSObject, ObservableObject {
    static let shared = TerminalSettings()
    @Published private(set) var preferred: TerminalApplication
    @Published private(set) var installed: [TerminalApplication: URL] = [:]
    @Published private var fallback: Notice?
    var fallbackNotice: String? { fallback?.text }

    private override init() {
        let defaults = UserDefaults.standard
        let legacy = defaults.object(forKey: MenuSettingsTransport.storageKey) != nil
            || defaults.object(forKey: "authorizedDirectories.v1") != nil
        preferred = TerminalPreference.load(from: defaults, legacyUser: legacy,
            itermInstalled: NSWorkspace.shared.urlForApplication(withBundleIdentifier: TerminalApplication.iterm2.bundleID) != nil)
        super.init()
        refresh()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationActivated(_:)),
            name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func applicationActivated(_ notification: Notification) { refresh() }

    func select(_ application: TerminalApplication) {
        refresh()
        guard installed[application] != nil else { return }
        preferred = application
        UserDefaults.standard.set(application.rawValue, forKey: TerminalPreference.key)
        fallback = nil
    }

    func refresh() {
        installed = Dictionary(uniqueKeysWithValues: TerminalApplication.allCases.compactMap { application in
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: application.bundleID),
                  FileManager.default.fileExists(atPath: url.path) else { return nil }
            return (application, url)
        })
    }

    struct Notice {
        let application: TerminalApplication
        let launchFailed: Bool
        var text: String {
            L10n.text(launchFailed ? "%@ 打开失败，本次已改用系统终端。" : "未找到 %@，本次已改用系统终端。", application.name)
        }
    }

    struct OpenResult {
        let application: TerminalApplication
        let notice: Notice?
    }

    func open(_ directory: URL) async throws -> OpenResult {
        refresh()
        let selected = preferred
        let resolved = try TerminalPreference.resolve(selected, installed: Set(installed.keys))
        var notice: Notice? = resolved == selected ? nil : Notice(application: selected, launchFailed: false)
        do {
            try await launch(resolved, directory: directory)
            fallback = notice
            return OpenResult(application: resolved, notice: notice)
        } catch {
            guard resolved != .system, installed[.system] != nil else { throw error }
            try await launch(.system, directory: directory)
            notice = Notice(application: selected, launchFailed: true)
            fallback = notice
            return OpenResult(application: .system, notice: notice)
        }
    }

    private func launch(_ application: TerminalApplication, directory: URL) async throws {
        guard let appURL = installed[application] else { throw TerminalPreferenceError.unavailable }
        let url = try application.openURL(for: directory)
        _ = try await NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: .init())
    }
}
