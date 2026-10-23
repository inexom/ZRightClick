import Foundation

struct TerminalRequest {
    let target: URL
    let isContainer: Bool

    init?(url: URL) {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme == "zrightclick", parts.host == "open-terminal",
              parts.user == nil, parts.password == nil, parts.port == nil,
              parts.fragment == nil, parts.path.isEmpty,
              let items = parts.queryItems, items.count == 2,
              items.filter({ $0.name == "path" }).count == 1,
              items.filter({ $0.name == "kind" }).count == 1,
              let path = items.first(where: { $0.name == "path" })?.value,
              path.hasPrefix("/"), !path.utf8.contains(0),
              let kind = items.first(where: { $0.name == "kind" })?.value,
              ["container", "item"].contains(kind) else { return nil }
        target = URL(fileURLWithPath: path).standardizedFileURL
        isContainer = kind == "container"
    }

    // Compare path components, so granting /work never grants /work-other.
    static func contains(_ target: URL, in root: URL) -> Bool {
        let rootParts = root.standardizedFileURL.pathComponents
        return target.standardizedFileURL.pathComponents.starts(with: rootParts)
    }
}
