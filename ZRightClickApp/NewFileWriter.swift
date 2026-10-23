import Foundation

struct NewFileWriter {
    static func content(for type: FileTypeDefinition, bundle: Bundle = .main) throws -> Data {
        if ["docx", "xlsx", "pptx"].contains(type.id) {
            guard let url = bundle.url(forResource: "Blank", withExtension: type.suffix, subdirectory: "Templates")
                    ?? bundle.url(forResource: "Blank", withExtension: type.suffix) else {
                throw WriterError.message("缺少内置文档模板，请重新安装 ZRightClick。")
            }
            return try Data(contentsOf: url)
        }
        return Data()
    }

    static func create(in directory: URL, suffix: String, data: Data) throws -> URL {
        guard MenuConfiguration.normalizedSuffix(suffix) == suffix else {
            throw WriterError.message("文件后缀无效。")
        }
        // Exclusive creation avoids the check-then-write race and refuses to
        // overwrite existing files, folders or symbolic links of the same name.
        let base = L10n.text("未命名")
        for index in 1...10_000 {
            let stem = index == 1 ? base : "\(base) \(index)"
            let url = directory.appendingPathComponent("\(stem).\(suffix)")
            do {
                try data.write(to: url, options: .withoutOverwriting)
                return url
            } catch let error as NSError {
                if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteFileExistsError { continue }
                throw error
            }
        }
        throw WriterError.message("同名文件过多，请整理目录后重试。")
    }

    enum WriterError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case let .message(text) = self { return L10n.text(text) }; return nil }
    }
}
