import AppKit
import Combine

@MainActor
final class MenuSettings: NSObject, ObservableObject {
    static let shared = MenuSettings()
    enum Tab: Hashable { case menus, types, terminal, access }
    @Published var selectedTab: Tab = .menus
    @Published private(set) var configuration = MenuSettingsTransport.load()

    private override init() {
        super.init()
        L10n.use(configuration.language ?? .initial)
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(publish), name: MenuSettingsTransport.requested, object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    @objc func publish() { MenuSettingsTransport.publish(configuration) }

    func update(_ mutation: (inout MenuConfiguration) -> Void) {
        var value = configuration
        mutation(&value)
        guard value.isValid else { return }
        L10n.use(value.language ?? .initial)
        configuration = value
        MenuSettingsTransport.save(value)
        publish()
    }

    func add(name: String, suffix input: String) throws {
        guard let suffix = MenuConfiguration.normalizedSuffix(input) else {
            throw SettingsError.message("请输入有效后缀，例如 txt、js 或 d.ts，不包含路径或空格。")
        }
        guard !MenuConfiguration.unsupportedFormats.contains(suffix) else {
            throw SettingsError.message("此格式需要专用模板，当前不能作为自定义空文件添加。")
        }
        guard !FileTypeDefinition.builtins.contains(where: { $0.suffix == suffix }),
              !configuration.customTypes.contains(where: { $0.suffix == suffix }) else {
            throw SettingsError.message("这个后缀已经存在，请直接勾选已有类型。")
        }
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.count <= 60, !title.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
              configuration.customTypes.count < 40 else {
            throw SettingsError.message("名称最多 60 个字符，自定义类型最多 40 项。")
        }
        update { $0.customTypes.append(CustomFileType(name: title.isEmpty ? L10n.text("%@ 文件", suffix.uppercased()) : title, suffix: suffix)) }
    }

    enum SettingsError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case let .message(value) = self { return L10n.text(value) }; return nil }
    }
}
