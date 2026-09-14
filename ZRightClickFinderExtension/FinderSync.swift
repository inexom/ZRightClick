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
            let item = NSMenuItem(
                title: "复制路径",
                action: #selector(copyPath(_:)),
                keyEquivalent: ""
            )
            item.target = self
            menu.addItem(item)
        default:
            break
        }
        return menu
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
        pasteboard.setString(text, forType: .string)
        log.info("已复制 \(targets.count) 条路径")
    }
}
