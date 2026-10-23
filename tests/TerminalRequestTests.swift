import Foundation

@main
struct TerminalRequestTests {
    static func main() {
        for path in ["/Users/test/中文 空格", "/tmp/a&b?#%+'\"", "/", "/tmp/line\nbreak"] {
            var parts = URLComponents()
            parts.scheme = "zrightclick"
            parts.host = "open-terminal"
            parts.queryItems = [URLQueryItem(name: "path", value: path), URLQueryItem(name: "kind", value: "item")]
            let request = TerminalRequest(url: parts.url!)!
            precondition(request.target.path == URL(fileURLWithPath: path).standardizedFileURL.path)
            precondition(!request.isContainer)
        }
        for text in [
            "https://open-terminal?path=/tmp&kind=item",
            "zrightclick://run?path=/tmp&kind=item",
            "zrightclick://open-terminal?path=relative&kind=item",
            "zrightclick://open-terminal?path=/tmp&path=/other&kind=item",
            "zrightclick://open-terminal?path=/tmp&kind=command",
            "zrightclick://open-terminal?path=/tmp%00bad&kind=item",
            "zrightclick://open-terminal?path=/tmp&kind=item&command=whoami",
            "zrightclick://user@open-terminal?path=/tmp&kind=item",
            "zrightclick://open-terminal/extra?path=/tmp&kind=item",
            "zrightclick://open-terminal?path=/tmp&kind=item#fragment"
        ] {
            precondition(TerminalRequest(url: URL(string: text)!) == nil, text)
        }
        let root = URL(fileURLWithPath: "/work")
        precondition(TerminalRequest.contains(URL(fileURLWithPath: "/work/child"), in: root))
        precondition(TerminalRequest.contains(root, in: root))
        precondition(!TerminalRequest.contains(URL(fileURLWithPath: "/work-other"), in: root))
        precondition(!TerminalRequest.contains(URL(fileURLWithPath: "/work/../private"), in: root))
        print("TerminalRequest tests passed: special characters, invalid requests, directory boundaries")
    }
}
