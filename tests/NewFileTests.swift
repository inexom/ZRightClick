import Foundation

func check(_ value: Bool, _ message: String = "") { precondition(value, message) }

@main
struct NewFileTests {
    static func main() throws {
        L10n.use(.chinese)
        check(MenuConfiguration().isValid)
        check(MenuConfiguration().enabledTypes.count == 5)
        check(MenuConfiguration.normalizedSuffix(" .TXT ") == "txt")
        check(MenuConfiguration.normalizedSuffix("d.ts") == "d.ts")
        for invalid in ["", "..", "a/b", "a\\b", "a:b", "a\nb", ".", "a..b", "a%00"] {
            check(MenuConfiguration.normalizedSuffix(invalid) == nil, invalid)
        }
        var config = MenuConfiguration()
        config.customTypes = [.init(name: "测试脚本", suffix: "js")]
        check(config.isValid)
        config.disabledBuiltinIDs.insert("docx")
        check(!config.enabledTypes.contains(where: { $0.id == "docx" }))
        config.newFileEnabled = false
        let encoded = try JSONEncoder().encode(config)
        check(try JSONDecoder().decode(MenuConfiguration.self, from: encoded) == config)
        check(MenuSettingsTransport.decode(String(data: encoded, encoding: .utf8)) == config)
        config.customTypes.append(.init(name: "重复", suffix: "js"))
        check(!config.isValid)
        check(MenuSettingsTransport.decode("{}") == nil)
        var duplicateBuiltin = MenuConfiguration()
        duplicateBuiltin.customTypes = [.init(name: "假的 Office", suffix: "docx")]
        check(!duplicateBuiltin.isValid)

        var parts = URLComponents()
        parts.scheme = "zrightclick"; parts.host = "create-file"
        let path = "/tmp/中文 空格 & # ?"
        parts.queryItems = [.init(name: "path", value: path), .init(name: "type", value: "docx")]
        check(NewFileRequest(url: parts.url!)?.directory.path == path)
        for invalid in [
            "zrightclick://create-file?path=relative&type=txt",
            "zrightclick://create-file?path=/tmp&type=../../escape",
            "zrightclick://create-file?path=/tmp&type=txt&type=md",
            "zrightclick://create-file?path=/tmp%00bad&type=txt",
            "zrightclick://create-file?path=/tmp&type=txt&command=bad",
            "zrightclick://user@create-file?path=/tmp&type=txt"
        ] { check(NewFileRequest(url: URL(string: invalid)!) == nil) }

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = directory.appendingPathComponent("未命名.txt")
        try Data("preserve me".utf8).write(to: original)
        let second = try NewFileWriter.create(in: directory, suffix: "txt", data: Data("new".utf8))
        check(second.lastPathComponent == "未命名 2.txt")
        check(try String(contentsOf: original, encoding: .utf8) == "preserve me")
        try FileManager.default.createSymbolicLink(at: directory.appendingPathComponent("未命名.md"), withDestinationURL: original)
        let markdown = try NewFileWriter.create(in: directory, suffix: "md", data: Data())
        check(markdown.lastPathComponent == "未命名 2.md")
        check(try String(contentsOf: original, encoding: .utf8) == "preserve me")
        let lock = NSLock()
        var results: [URL] = []
        DispatchQueue.concurrentPerform(iterations: 20) { _ in
            do {
                let url = try NewFileWriter.create(in: directory, suffix: "js", data: Data("test".utf8))
                lock.lock(); results.append(url); lock.unlock()
            } catch { fatalError("Concurrent creation failed: \(error)") }
        }
        check(Set(results).count == 20)
        for url in results { check(try Data(contentsOf: url) == Data("test".utf8)) }
        print("New file tests passed: settings validation, request boundaries, no overwrite, symlink collision, concurrent naming")
    }
}
