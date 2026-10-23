import AppKit
import Combine
import os

@MainActor
final class FileActionController: ObservableObject {
    static let shared = FileActionController()
    @Published private var statusText: () -> String = { L10n.text("已准备好。设置会自动保存，右键菜单下次打开时生效。") }
    var status: String { statusText() }
    @Published private(set) var isTestingTerminal = false
    private let terminals = TerminalSettings.shared
    private let log = Logger(subsystem: "com.inexom.zrightclick", category: "FileActions")
    private var pending: [Action] = []
    private var processing = false

    private enum Action {
        case terminal(TerminalRequest)
        case create(NewFileRequest)
        case testTerminal
    }

    func receive(_ url: URL) {
        if let request = TerminalRequest(url: url) { enqueue(.terminal(request)) }
        else if let request = NewFileRequest(url: url) { enqueue(.create(request)) }
        else { log.error("忽略无效的文件操作请求") }
    }

    func testTerminal() {
        guard !isTestingTerminal else { return }
        isTestingTerminal = true
        enqueue(.testTerminal)
    }

    private func enqueue(_ action: Action) {
        pending.append(action)
        guard !processing else { return }
        processing = true
        Task {
            while !pending.isEmpty {
                let action = pending.removeFirst()
                do {
                    switch action {
                    case let .terminal(request): try await openTerminal(request)
                    case let .create(request): try await createFile(request)
                    case .testTerminal: try await performTerminalTest()
                    }
                } catch {
                    showError(error)
                }
            }
            processing = false
        }
    }

    private func openTerminal(_ request: TerminalRequest) async throws {
        guard MenuSettings.shared.configuration.terminalEnabled else { statusText = { L10n.text("“在此处打开终端”已停用。") }; return }
        let suggested = request.isContainer ? request.target : request.target.deletingLastPathComponent()
        guard let root = try await DirectoryAccessStore.shared.authorize(target: request.target, suggestedDirectory: suggested, write: false) else {
            statusText = { L10n.text("已取消授权，未打开终端。") }; return
        }
        defer { root.stopAccessingSecurityScopedResource() }
        let target = request.target.resolvingSymlinksInPath()
        let directory = try target.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true ? target : target.deletingLastPathComponent()
        guard DirectoryAccessStore.covers(directory, root: root) else { throw ActionError.message("目标目录超出授权范围。") }
        guard MenuSettings.shared.configuration.terminalEnabled else { return }
        try await launchTerminal(in: directory)
    }

    private func performTerminalTest() async throws {
        defer { isTestingTerminal = false }
        let panel = NSOpenPanel()
        panel.title = L10n.text("测试默认终端")
        panel.message = L10n.text("选择要在默认终端中打开的文件夹。此次选择仅用于测试，不新增保存的目录授权。")
        panel.prompt = L10n.text("测试打开")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        NSApp.activate(ignoringOtherApps: true)
        guard await panel.begin() == .OK, let directory = panel.url else {
            statusText = { L10n.text("已取消终端测试。") }; return
        }
        let active = directory.startAccessingSecurityScopedResource()
        defer { if active { directory.stopAccessingSecurityScopedResource() } }
        guard try directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            throw ActionError.message("请选择有效的文件夹。")
        }
        try await launchTerminal(in: directory)
    }

    private func launchTerminal(in directory: URL) async throws {
        let result = try await terminals.open(directory)
        statusText = { (result.notice.map { $0.text + " " } ?? "") + L10n.text("已请求 %@ 打开：%@", result.application.name, directory.path) }
        log.info("打开终端请求成功：\(result.application.rawValue, privacy: .public)，回退=\(result.notice != nil)")
    }

    private func createFile(_ request: NewFileRequest) async throws {
        guard MenuSettings.shared.configuration.newFileEnabled,
              MenuSettings.shared.configuration.enabledTypes.contains(where: { $0.id == request.typeID }) else {
            statusText = { L10n.text("“新建文件”或此类型已停用。") }; return
        }
        guard let root = try await DirectoryAccessStore.shared.authorize(
            target: request.directory, suggestedDirectory: request.directory, write: true
        ) else { statusText = { L10n.text("已取消授权，未创建文件。") }; return }
        defer { root.stopAccessingSecurityScopedResource() }
        let directory = request.directory.resolvingSymlinksInPath()
        guard DirectoryAccessStore.covers(directory, root: root),
              try directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == true else {
            throw ActionError.message("目标不是有效的已授权文件夹。")
        }
        // Settings might have changed while the authorization panel was open.
        guard MenuSettings.shared.configuration.newFileEnabled,
              let type = MenuSettings.shared.configuration.enabledTypes.first(where: { $0.id == request.typeID }) else { return }
        let file = try NewFileWriter.create(in: directory, suffix: type.suffix, data: NewFileWriter.content(for: type))
        NSWorkspace.shared.activateFileViewerSelecting([file])
        statusText = { L10n.text("已创建：%@", file.path) }
        log.info("文件创建成功：\(file.lastPathComponent, privacy: .private)")
    }

    private func showError(_ error: Error) {
        statusText = { error.localizedDescription }
        let message = error.localizedDescription
        log.error("文件操作失败：\(message, privacy: .private)")
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = L10n.text("操作未完成")
        alert.informativeText = message
        alert.addButton(withTitle: L10n.text("好"))
        alert.runModal()
    }

    enum ActionError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case let .message(text) = self { return L10n.text(text) }; return nil }
    }
}
