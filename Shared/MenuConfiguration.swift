import Foundation

struct FileTypeDefinition: Identifiable, Equatable {
    let id: String
    let name: String
    let suffix: String
    let symbol: String
    let color: String
    var title: String { "\(name) (.\(suffix))" }

    static var builtins: [Self] { [
        .init(id: "txt", name: L10n.text("文本文件"), suffix: "txt", symbol: "doc.text", color: "gray"),
        .init(id: "md", name: "Markdown", suffix: "md", symbol: "text.alignleft", color: "indigo"),
        .init(id: "docx", name: L10n.text("Word 文档"), suffix: "docx", symbol: "doc.richtext", color: "blue"),
        .init(id: "xlsx", name: L10n.text("Excel 工作簿"), suffix: "xlsx", symbol: "tablecells", color: "green"),
        .init(id: "pptx", name: L10n.text("PowerPoint 演示文稿"), suffix: "pptx", symbol: "rectangle.on.rectangle", color: "orange"),
    ] }
}

struct CustomFileType: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var suffix: String
    var enabled = true
    var definition: FileTypeDefinition {
        .init(id: id, name: name, suffix: suffix, symbol: "doc", color: "gray")
    }
}

struct MenuConfiguration: Codable, Equatable {
    // Optional for compatibility with settings saved before language switching.
    var language: AppLanguage?
    var newFileEnabled = true
    var copyPathEnabled = true
    var terminalEnabled = true
    var disabledBuiltinIDs: Set<String> = []
    var customTypes: [CustomFileType] = []

    var enabledTypes: [FileTypeDefinition] {
        FileTypeDefinition.builtins.filter { !disabledBuiltinIDs.contains($0.id) }
        + customTypes.filter(\.enabled).map(\.definition)
    }

    // Configuration received across processes is untrusted and never contains
    // commands, paths or security-scoped bookmarks.
    var isValid: Bool {
        let builtinIDs = Set(FileTypeDefinition.builtins.map(\.id))
        guard disabledBuiltinIDs.isSubset(of: builtinIDs), customTypes.count <= 40 else { return false }
        var ids = builtinIDs
        var suffixes = Set(FileTypeDefinition.builtins.map(\.suffix))
        for type in customTypes {
            guard UUID(uuidString: type.id) != nil, ids.insert(type.id).inserted,
                  Self.normalizedSuffix(type.suffix) == type.suffix,
                  !Self.unsupportedFormats.contains(type.suffix),
                  suffixes.insert(type.suffix).inserted,
                  !type.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  type.name.count <= 60, !type.name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
            else { return false }
        }
        return true
    }

    static let unsupportedFormats: Set<String> = ["doc", "xls", "ppt", "pdf", "zip", "pages", "numbers", "key", "png", "jpg", "jpeg"]

    static func normalizedSuffix(_ input: String) -> String? {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasPrefix(".") { value.removeFirst() }
        guard value.count <= 40,
              value.range(of: "^[a-z0-9][a-z0-9_+-]*(\\.[a-z0-9][a-z0-9_+-]*)*$", options: .regularExpression) != nil else { return nil }
        return value
    }
}

enum MenuSettingsTransport {
    static let storageKey = "menuConfiguration.v1"
    static let changed = Notification.Name("com.inexom.zrightclick.menuConfiguration.changed.v1")
    static let requested = Notification.Name("com.inexom.zrightclick.menuConfiguration.requested.v1")

    static func load() -> MenuConfiguration {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let config = try? JSONDecoder().decode(MenuConfiguration.self, from: data), config.isValid else {
            return MenuConfiguration()
        }
        return config
    }

    static func save(_ config: MenuConfiguration) {
        guard config.isValid, let data = try? JSONEncoder().encode(config) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func publish(_ config: MenuConfiguration) {
        guard config.isValid, let data = try? JSONEncoder().encode(config),
              let payload = String(data: data, encoding: .utf8) else { return }
        // App Sandbox requires nil userInfo for distributed notifications.
        DistributedNotificationCenter.default().postNotificationName(
            changed, object: payload, userInfo: nil, deliverImmediately: true
        )
    }

    static func decode(_ object: Any?) -> MenuConfiguration? {
        guard let text = object as? String, text.utf8.count < 20_000,
              let data = text.data(using: .utf8),
              let config = try? JSONDecoder().decode(MenuConfiguration.self, from: data), config.isValid else { return nil }
        return config
    }
}
