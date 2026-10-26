import AppKit
import Combine
import FinderSync

/// Only observes the system election. Opening Settings is never treated as consent.
@MainActor
final class ExtensionSetup: ObservableObject {
    static let shared = ExtensionSetup()
    private static let completedKey = "extensionSetup.completed.v1"

    @Published private(set) var isEnabled = FIFinderSyncController.isExtensionEnabled
    @Published var isGuidePresented = false
    private var timer: Timer?
    private var activationObserver: NSObjectProtocol?

    func start() {
        refresh()
        if !isEnabled && !UserDefaults.standard.bool(forKey: Self.completedKey) {
            isGuidePresented = true
        }
        guard timer == nil else { return }
        // Poll only while the settings view exists, including while the user is
        // in System Settings. Closing the window releases this timer.
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }
    }

    func refresh() {
        let enabled = FIFinderSyncController.isExtensionEnabled
        if isEnabled != enabled { isEnabled = enabled }
    }

    func openSystemSettings() {
        FIFinderSyncController.showExtensionManagementInterface()
    }

    func finish() {
        refresh()
        guard isEnabled else { return }
        UserDefaults.standard.set(true, forKey: Self.completedKey)
        isGuidePresented = false
    }
}
