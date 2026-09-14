import Cocoa
import FinderSync
import os

private let log = Logger(subsystem: "com.inexom.zrightclick", category: "FinderSync")

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        log.info("扩展已加载: \(Bundle.main.bundlePath, privacy: .public)")
        updateObservedDirectories()

        // 挂载/卸载磁盘时重新登记，否则新插入的外置硬盘上不会出现菜单
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(volumesDidChange),
            name: NSWorkspace.didMountNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(volumesDidChange),
            name: NSWorkspace.didUnmountNotification,
            object: nil
        )
    }

    @objc private func volumesDidChange() {
        updateObservedDirectories()
    }

    /// 沙盒里 NSHomeDirectory() 返回的是扩展自己的容器路径，拿不到用户真实家目录。
    private func realHomeDirectory() -> URL {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }

    /// Finder 只在这里登记过的目录树下显示我们的菜单，没登记就完全看不到。
    private func updateObservedDirectories() {
        var urls: Set<URL> = [
            URL(fileURLWithPath: "/", isDirectory: true),
            URL(fileURLWithPath: "/Volumes", isDirectory: true),
            realHomeDirectory(),
        ]
        // 沙盒下这个调用常常返回空，所以上面几条是兜底
        let volumes = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: nil,
            options: [.skipHiddenVolumes]
        ) ?? []
        urls.formUnion(volumes)
        FIFinderSyncController.default().directoryURLs = urls
        for url in urls.sorted(by: { $0.path < $1.path }) {
            log.info("登记目录: \(url.path, privacy: .public)")
        }
    }

    // MARK: - 菜单

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "ZRightClick")
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer:
            add(title: "复制路径", action: #selector(copyPath(_:)), to: menu)
            add(title: "在此处打开终端", action: #selector(openInTerminal(_:)), to: menu)
        default:
            break
        }
        return menu
    }

    private func add(title: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    /// 选中的文件；在空白处右键时退化为当前所在文件夹。
    private func currentTargets() -> [URL] {
        let selected = FIFinderSyncController.default().selectedItemURLs() ?? []
        if !selected.isEmpty { return selected }
        if let container = FIFinderSyncController.default().targetedURL() { return [container] }
        return []
    }

    @objc func copyPath(_ sender: AnyObject?) {
        let targets = currentTargets()
        guard !targets.isEmpty else {
            log.error("复制路径：没有拿到任何目标")
            return
        }
        let text = targets.map(\.path).joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let ok = pasteboard.setString(text, forType: .string)
        log.info("复制 \(targets.count) 条路径, 写入成功=\(ok)")
    }

    /// 选中文件时取它所在的文件夹，选中文件夹时取它本身。
    private func containingDirectory() -> URL? {
        guard let first = currentTargets().first else { return nil }
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: first.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            return first
        }
        return first.deletingLastPathComponent()
    }

    @objc func openInTerminal(_ sender: AnyObject?) {
        guard let directory = containingDirectory() else {
            log.error("打开终端：没有拿到目标目录")
            return
        }

        // 装了 iTerm2 就优先用，否则退回系统终端。
        // 走 LaunchServices 查询而不是直接拼 /Applications 路径，沙盒下前者才可靠。
        let candidates = ["com.googlecode.iterm2", "com.apple.Terminal"]
        let terminal = candidates.lazy
            .compactMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }
            .first

        guard let terminal else {
            log.error("打开终端：没找到可用的终端 App")
            return
        }

        log.info("打开终端: \(terminal.lastPathComponent, privacy: .public) 目录=\(directory.path, privacy: .public)")
        NSWorkspace.shared.open(
            [directory],
            withApplicationAt: terminal,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, error in
            if let error {
                log.error("打开终端失败: \(error.localizedDescription, privacy: .public)")
            } else {
                log.info("打开终端成功")
            }
        }
    }
}
