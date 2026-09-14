import SwiftUI

@main
struct ZRightClickApp: App {
    var body: some Scene {
        WindowGroup("ZRightClick") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ZRightClick")
                .font(.largeTitle.bold())
            Text("Finder 右键菜单增强")
                .foregroundStyle(.secondary)

            Divider()

            Text("首次使用需要手动启用扩展：")
            Text("系统设置 → 通用 → 登录项与扩展 → 访达扩展 → 勾选 ZRightClick")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button("打开扩展设置") {
                let url = URL(
                    string: "x-apple.systempreferences:com.apple.ExtensionsPreferences"
                )!
                NSWorkspace.shared.open(url)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

#Preview {
    ContentView()
}
