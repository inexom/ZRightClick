import Cocoa
import FinderSync
import os

private let log = Logger(subsystem: "com.inexom.zrightclick", category: "FinderSync")

class FinderSync: FIFinderSync {
    private let stateLock = NSRecursiveLock()
    private var nextCreationTag = 0
    private var menuTargets: [URL] = []
    private var targetsContainer = false
    private var configuration = MenuSettingsTransport.load()
    private var creationTargets: [Int: (path: String, typeID: String)] = [:]

    override init() {
        super.init()
        L10n.use(configuration.language ?? .initial)
        log.info("扩展已加载: \(Bundle.main.bundlePath, privacy: .public)")
        updateObservedDirectories()
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(settingsChanged(_:)), name: MenuSettingsTransport.changed,
            object: nil, suspensionBehavior: .deliverImmediately
        )
        requestSettings()

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

    @objc private func settingsChanged(_ notification: Notification) {
        guard let value = MenuSettingsTransport.decode(notification.object) else { return }
        stateLock.withLock { configuration = value }
        L10n.use(value.language ?? .initial)
        MenuSettingsTransport.save(value)
        log.info("菜单配置已更新")
    }

    private func requestSettings() {
        DistributedNotificationCenter.default().postNotificationName(
            MenuSettingsTransport.requested, object: nil, userInfo: nil, deliverImmediately: true
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
        let controller = FIFinderSyncController.default()
        let container = controller.targetedURL()
        var isContainer = menuKind == .contextualMenuForContainer
        var targets = isContainer ? [] : (controller.selectedItemURLs() ?? [])
        if targets.isEmpty, let container {
            targets = [container]
            isContainer = true
        }
        // Never hold a state lock across AppKit drawing or distributed IPC.
        let configuration = stateLock.withLock {
            menuTargets = targets
            targetsContainer = isContainer
            if creationTargets.count > 128 { creationTargets.removeAll() }
            return self.configuration
        }
        let menu = NSMenu(title: "ZRightClick")
        switch menuKind {
        case .contextualMenuForItems, .contextualMenuForContainer:
            requestSettings()
            if menuKind == .contextualMenuForContainer, configuration.newFileEnabled {
                let parent = NSMenuItem(title: L10n.text("新建文件"), action: nil, keyEquivalent: "")
                let submenu = NSMenu(title: L10n.text("新建文件"))
                for type in configuration.enabledTypes {
                    let item = NSMenuItem(title: type.title, action: #selector(createFile(_:)), keyEquivalent: "")
                    item.target = self
                    // Capture the directory per menu item, independent of later Finder selection.
                    item.tag = stateLock.withLock {
                        nextCreationTag &+= 1
                        creationTargets[nextCreationTag] = (container?.path ?? "", type.id)
                        return nextCreationTag
                    }
                    item.image = type.icon
                    submenu.addItem(item)
                }
                if submenu.items.isEmpty {
                    let empty = NSMenuItem(title: L10n.text("请先启用文件类型"), action: nil, keyEquivalent: "")
                    empty.isEnabled = false
                    submenu.addItem(empty)
                }
                submenu.addItem(.separator())
                add(title: L10n.text("管理文件类型…"), action: #selector(manageTypes(_:)), to: submenu)
                parent.submenu = submenu
                menu.addItem(parent)
            }
            if configuration.copyPathEnabled {
                add(title: L10n.text("复制路径"), action: #selector(copyPath(_:)), to: menu)
            }
            if configuration.terminalEnabled {
                add(title: L10n.text("在此处打开终端"), action: #selector(openInTerminal(_:)), to: menu)
            }
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
        stateLock.withLock { menuTargets }
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

    @objc func openInTerminal(_ sender: AnyObject?) {
        let (selection, isContainer) = stateLock.withLock { (menuTargets.first, targetsContainer) }
        guard let target = selection else { return }
        // 仅传路径；目录类型判断与文件访问都由取得用户授权的主应用完成。
        var components = URLComponents()
        components.scheme = "zrightclick"
        components.host = "open-terminal"
        components.queryItems = [
            URLQueryItem(name: "path", value: target.path),
            URLQueryItem(name: "kind", value: isContainer ? "container" : "item"),
        ]
        send(components)
    }

    @objc private func createFile(_ sender: NSMenuItem) {
        log.info("收到新建菜单动作，tag=\(sender.tag)")
        guard let target = stateLock.withLock({ creationTargets[sender.tag] }), !target.path.isEmpty else {
            log.error("无法恢复新建文件目标")
            return
        }
        let path = target.path
        let type = target.typeID
        var request = URLComponents()
        request.scheme = "zrightclick"
        request.host = "create-file"
        request.queryItems = [URLQueryItem(name: "path", value: path), URLQueryItem(name: "type", value: type)]
        send(request)
    }

    @objc private func manageTypes(_ sender: AnyObject?) {
        var request = URLComponents()
        request.scheme = "zrightclick"
        request.host = "settings"
        send(request)
    }

    private func send(_ components: URLComponents) {
        guard let request = components.url,
              let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.inexom.zrightclick") else {
            log.error("找不到 ZRightClick 主应用")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.open([request], withApplicationAt: app, configuration: configuration) { _, error in
            if let error { log.error("转交主应用失败: \(error.localizedDescription, privacy: .public)") }
        }
    }
}
