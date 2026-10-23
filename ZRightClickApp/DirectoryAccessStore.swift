import AppKit
import Combine
import os

@MainActor
final class DirectoryAccessStore: ObservableObject {
    static let shared = DirectoryAccessStore()
    private let key = "authorizedDirectories.v1"
    private let log = Logger(subsystem: "com.inexom.zrightclick", category: "DirectoryAccess")

    struct Grant: Codable, Identifiable {
        var id = UUID()
        var path: String
        var bookmark: Data
        // Missing in v1 bookmarks created by the previous read-only version.
        var writable: Bool?
    }

    @Published private(set) var grants: [Grant] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Grant].self, from: data) { grants = saved }
    }

    func remove(_ id: UUID) {
        grants.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(grants) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func bookmark(_ root: URL, write: Bool) throws -> Data {
        try root.bookmarkData(options: write ? [.withSecurityScope] : [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                              includingResourceValuesForKeys: nil, relativeTo: nil)
    }

    static func covers(_ target: URL, root: URL) -> Bool {
        TerminalRequest.contains(target.resolvingSymlinksInPath(), in: root.resolvingSymlinksInPath())
    }

    // The returned scope remains active until the action caller releases it.
    private func restore(target: URL, write: Bool) -> URL? {
        for index in grants.indices {
            guard !write || grants[index].writable == true else { continue }
            do {
                var stale = false
                let root = try URL(resolvingBookmarkData: grants[index].bookmark, options: [.withSecurityScope, .withoutUI],
                                   relativeTo: nil, bookmarkDataIsStale: &stale)
                guard root.startAccessingSecurityScopedResource() else { continue }
                if stale, let data = try? bookmark(root, write: grants[index].writable == true) {
                    grants[index].bookmark = data
                    grants[index].path = root.path
                    persist()
                }
                if Self.covers(target, root: root) { return root }
                root.stopAccessingSecurityScopedResource()
            } catch {
                log.error("恢复目录授权失败: \(error.localizedDescription)")
            }
        }
        return nil
    }

    func authorize(target: URL, suggestedDirectory: URL, write: Bool) async throws -> URL? {
        if let root = restore(target: target, write: write) { return root }
        let panel = NSOpenPanel()
        panel.title = write ? L10n.text("允许在此目录新建文件") : L10n.text("允许在此目录打开终端")
        panel.message = L10n.text("请选择目标目录或它的上级目录。%@\n目标：%@\n授权会保存，可在设置中移除。",
            L10n.text(write ? "需要读写权限；已有只读授权不会自动升级。" : "授权只用于访问目录。"), target.path)
        panel.prompt = write ? L10n.text("授权读写") : L10n.text("授权目录")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = suggestedDirectory
        NSApp.activate(ignoringOtherApps: true)
        guard await panel.begin() == .OK, let selected = panel.url else { return nil }
        let active = selected.startAccessingSecurityScopedResource()
        defer { if active { selected.stopAccessingSecurityScopedResource() } }
        guard Self.covers(target, root: selected) else {
            throw AccessError.message("所选目录不包含目标，请选择目标目录或它的上级目录。")
        }
        let data = try bookmark(selected, write: write)
        // Reauthorizing this exact location replaces only that location's grant.
        grants.removeAll { $0.path == selected.path }
        grants.append(Grant(path: selected.path, bookmark: data, writable: write))
        persist()
        guard let root = restore(target: target, write: write) else {
            throw AccessError.message("目录授权无法恢复，请在设置中移除该授权后重试。")
        }
        return root
    }

    enum AccessError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case let .message(text) = self { return L10n.text(text) }; return nil }
    }
}
