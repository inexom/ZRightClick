import Foundation

struct NewFileRequest {
    let directory: URL
    let typeID: String

    init?(url: URL) {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "zrightclick", parts.host == "create-file", parts.path.isEmpty,
              parts.user == nil, parts.password == nil, parts.port == nil, parts.fragment == nil,
              let items = parts.queryItems, items.count == 2,
              items.filter({ $0.name == "path" }).count == 1,
              items.filter({ $0.name == "type" }).count == 1,
              let path = items.first(where: { $0.name == "path" })?.value,
              path.hasPrefix("/"), !path.utf8.contains(0),
              let type = items.first(where: { $0.name == "type" })?.value,
              FileTypeDefinition.builtins.contains(where: { $0.id == type }) || UUID(uuidString: type) != nil
        else { return nil }
        directory = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        typeID = type
    }
}
