import Foundation

enum AppLanguage: String, Codable, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"

    static var initial: Self {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .chinese : .english
    }
}

enum L10n {
    static let changed = Notification.Name("com.inexom.zrightclick.language.changed")
    private static let lock = NSLock()
    private static var current = AppLanguage.initial

    static var language: AppLanguage { lock.withLock { current } }

    static func use(_ language: AppLanguage) {
        let changed = lock.withLock {
            guard current != language else { return false }
            current = language
            return true
        }
        if changed { NotificationCenter.default.post(name: Self.changed, object: nil) }
    }

    // Chinese keys are stable; only app-owned text is translated. User names,
    // paths and third-party errors are never used as localization keys.
    static func text(_ key: String, _ arguments: String...) -> String {
        let format = language == .english ? (english[key] ?? key) : key
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language.rawValue), arguments: arguments)
    }

    static let english: [String: String] = [
        "Finder 右键菜单增强": "Enhance Finder context menus",
        "扩展设置…": "Extension Settings…",
        "右键菜单": "Context Menu",
        "文件类型": "File Types",
        "终端": "Terminal",
        "目录授权": "Folder Access",
        "关闭窗口后继续在菜单栏运行，可从菜单栏重新打开或退出。": "Closing this window keeps the app in the menu bar. Reopen or quit from there.",
        "选择在 Finder 右键菜单中显示的功能。修改后自动保存，下次打开右键菜单时生效。": "Choose which actions appear in Finder. Changes are saved automatically and apply the next time you open a context menu.",
        "新建文件": "New File",
        "在文件夹空白处显示二级菜单，类型可在“文件类型”中勾选。": "Show a submenu in empty folder space. Choose formats in File Types.",
        "复制路径": "Copy Path",
        "支持同时复制多个选中文件或文件夹的路径。": "Copy the paths of multiple selected files or folders at once.",
        "在此处打开终端": "Open Terminal Here",
        "使用“终端”设置中选择的默认应用。": "Use the default app selected in Terminal settings.",
        "首次使用需在系统设置 → 通用 → 登录项与扩展 → 访达扩展中启用 ZRightClick。": "Enable ZRightClick in System Settings → General → Login Items & Extensions → Finder Extensions before first use.",
        "选择“在此处打开终端”使用的应用，选择后自动保存。": "Choose the app for Open Terminal Here. Your choice is saved automatically.",
        "默认终端": "Default terminal",
        "（未安装）": " (Not installed)",
        "未安装": "Not installed",
        "已安装": "Installed",
        "选择文件夹并测试…": "Choose Folder and Test…",
        "刷新安装状态": "Refresh Installed Apps",
        "所选应用未安装或无法启动时，本次会改用系统终端，并保留你的选择。测试打开不会新增保存的目录授权。": "If the selected app is missing or cannot launch, this request uses Terminal while keeping your preference. Testing does not save folder access.",
        "第三方终端首次使用时，可能需要先完成其自身的初始设置。": "Third-party terminals may require initial setup before first use.",
        "Finder 的“在此处打开终端”已关闭，仍可在这里配置和测试。": "Open Terminal Here is disabled in Finder. You can still configure and test it here.",
        "“新建文件”菜单已关闭。以下配置会保留，重新启用后生效。": "New File is disabled. Your file type settings are kept and will apply when it is enabled again.",
        "内置类型": "Built-in Types",
        "自定义类型": "Custom Types",
        "尚未添加。自定义类型会创建空文件，例如 js、py、json。": "No custom types yet. Custom types create empty files, such as js, py, and json.",
        "名称（可选）": "Name (optional)",
        "后缀，例如 js": "Extension, e.g. js",
        "添加": "Add",
        "内置类型只能启用或停用。Office 类型使用空白模板，无需安装 Office 即可创建；创建后在 Finder 中选中，不自动打开。": "Built-in types can be enabled or disabled. Office files use blank templates and do not require Office. New files are selected in Finder without opening them.",
        "内置": "Built-in",
        "删除": "Delete",
        "未找到默认打开应用，仍可创建文件": "No default app found. Files can still be created.",
        "默认打开：%@": "Opens with: %@",
        "打开终端使用只读授权，新建文件需要读写授权。首次操作时选择目标目录或它的上级目录，之后可复用授权。": "Opening a terminal needs read-only access; creating files needs read/write access. Select the target folder or a parent folder on first use. Saved access is reused.",
        "尚未授权目录": "No Authorized Folders",
        "使用 Finder 右键功能时会按需请求授权。": "Folder access is requested when needed by a Finder action.",
        "读写": "Read/write",
        "只读": "Read-only",
        "移除": "Remove",
        "移除后应用不再复用该授权。原有只读授权会保留，新建文件时需要额外确认写入权限。": "Removing an entry stops the app from reusing its access. Existing read-only access is kept; creating files requires additional write permission.",
        "文本文件": "Text File",
        "Word 文档": "Word Document",
        "Excel 工作簿": "Excel Workbook",
        "PowerPoint 演示文稿": "PowerPoint Presentation",
        "请先启用文件类型": "Enable a File Type First",
        "管理文件类型…": "Manage File Types…",
        "打开 ZRightClick": "Open ZRightClick",
        "退出 ZRightClick": "Quit ZRightClick",
        "编辑": "Edit",
        "剪切": "Cut",
        "拷贝": "Copy",
        "粘贴": "Paste",
        "全选": "Select All",
        "窗口": "Window",
        "最小化": "Minimize",
        "关闭窗口": "Close Window",
        "请输入有效后缀，例如 txt、js 或 d.ts，不包含路径或空格。": "Enter a valid extension, such as txt, js, or d.ts, without paths or spaces.",
        "此格式需要专用模板，当前不能作为自定义空文件添加。": "This format requires a dedicated template and cannot be added as an empty custom file.",
        "这个后缀已经存在，请直接勾选已有类型。": "This extension already exists. Enable the existing type instead.",
        "名称最多 60 个字符，自定义类型最多 40 项。": "Names can have up to 60 characters. You can add up to 40 custom types.",
        "%@ 文件": "%@ File",
        "系统终端": "Terminal",
        "无法打开无效的终端目录。": "Cannot open an invalid terminal directory.",
        "没有找到可用的终端，请检查系统终端是否存在。": "No terminal app is available. Check that Terminal is installed.",
        "未找到 %@，本次已改用系统终端。": "%@ was not found. This request used Terminal.",
        "%@ 打开失败，本次已改用系统终端。": "%@ could not launch. This request used Terminal.",
        "允许在此目录新建文件": "Allow File Creation in This Folder",
        "允许在此目录打开终端": "Allow Terminal Access to This Folder",
        "请选择目标目录或它的上级目录。%@\n目标：%@\n授权会保存，可在设置中移除。": "Select the target folder or a parent folder. %@\nTarget: %@\nAccess will be saved and can be removed in settings.",
        "需要读写权限；已有只读授权不会自动升级。": "Read/write access is required. Existing read-only access will not be upgraded automatically.",
        "授权只用于访问目录。": "Permission is used only to access the folder.",
        "授权读写": "Allow Read/Write",
        "授权目录": "Allow Folder Access",
        "所选目录不包含目标，请选择目标目录或它的上级目录。": "The selected folder does not contain the target. Select the target folder or a parent folder.",
        "目录授权无法恢复，请在设置中移除该授权后重试。": "Saved folder access could not be restored. Remove it in settings and try again.",
        "已准备好。设置会自动保存，右键菜单下次打开时生效。": "Ready. Settings are saved automatically and apply when you next open a context menu.",
        "“在此处打开终端”已停用。": "Open Terminal Here is disabled.",
        "已取消授权，未打开终端。": "Folder access was canceled. No terminal was opened.",
        "目标目录超出授权范围。": "The target folder is outside the authorized location.",
        "测试默认终端": "Test Default Terminal",
        "选择要在默认终端中打开的文件夹。此次选择仅用于测试，不新增保存的目录授权。": "Choose a folder to open in your default terminal. This selection is only for testing and does not save folder access.",
        "测试打开": "Test Open",
        "已取消终端测试。": "Terminal test canceled.",
        "请选择有效的文件夹。": "Select a valid folder.",
        "已请求 %@ 打开：%@": "Requested %@ to open: %@",
        "“新建文件”或此类型已停用。": "New File or this file type is disabled.",
        "已取消授权，未创建文件。": "Folder access was canceled. No file was created.",
        "目标不是有效的已授权文件夹。": "The target is not a valid authorized folder.",
        "已创建：%@": "Created: %@",
        "操作未完成": "Action Incomplete",
        "好": "OK",
        "缺少内置文档模板，请重新安装 ZRightClick。": "A built-in document template is missing. Reinstall ZRightClick.",
        "文件后缀无效。": "The file extension is invalid.",
        "未命名": "Untitled",
        "同名文件过多，请整理目录后重试。": "Too many files share this name. Organize the folder and try again.",
    ]
}
