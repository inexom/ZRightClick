import Foundation

@main
struct LocalizationTests {
    static func main() throws {
        // Pre-language settings still decode with toggles and custom names intact.
        let old = #"{"newFileEnabled":false,"copyPathEnabled":true,"terminalEnabled":false,"disabledBuiltinIDs":["md"],"customTypes":[{"id":"6C3C169F-598A-49DF-A027-C4B5627836F7","name":"我的脚本","suffix":"js","enabled":true}]}"#
        var config = try JSONDecoder().decode(MenuConfiguration.self, from: Data(old.utf8))
        precondition(config.language == nil && config.isValid)
        precondition(!config.newFileEnabled && !config.terminalEnabled)
        let custom = config.customTypes

        for language in AppLanguage.allCases {
            config.language = language
            let data = try JSONEncoder().encode(config)
            let restored = try JSONDecoder().decode(MenuConfiguration.self, from: data)
            precondition(restored == config)
            precondition(MenuSettingsTransport.decode(String(decoding: data, as: UTF8.self)) == config)
            L10n.use(language)
            precondition(config.customTypes == custom)
            precondition(config.customTypes[0].definition.title == "我的脚本 (.js)")
        }

        L10n.use(.english)
        precondition(FileTypeDefinition.builtins.first?.title == "Text File (.txt)")
        precondition(TerminalApplication.system.name == "Terminal")
        let path = "/tmp/中文 & 100% + 空格"
        precondition(L10n.text("已创建：%@", path) == "Created: " + path)
        precondition(L10n.text("已请求 %@ 打开：%@", "iTerm2", path) == "Requested iTerm2 to open: " + path)
        let error = NewFileWriter.WriterError.message("文件后缀无效。")
        precondition(error.localizedDescription == "The file extension is invalid.")
        L10n.use(.chinese)
        precondition(error.localizedDescription == "文件后缀无效。")
        precondition(FileTypeDefinition.builtins.first?.title == "文本文件 (.txt)")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        for language in AppLanguage.allCases {
            L10n.use(language)
            let base = language == .chinese ? "未命名" : "Untitled"
            let first = try NewFileWriter.create(in: directory, suffix: "txt", data: Data("original".utf8))
            let second = try NewFileWriter.create(in: directory, suffix: "txt", data: Data())
            precondition(first.lastPathComponent == "\(base).txt")
            precondition(second.lastPathComponent == "\(base) 2.txt")
            let original = try Data(contentsOf: first)
            precondition(original == Data("original".utf8))
        }
        for (key, value) in L10n.english {
            precondition(!value.isEmpty)
            precondition(key.components(separatedBy: "%@").count == value.components(separatedBy: "%@").count)
        }
        print("Localization tests passed: legacy settings, transport round-trip, live titles/errors, user content, format arguments, bilingual file naming")
    }
}
