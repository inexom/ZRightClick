import SwiftUI

struct ExtensionSetupView: View {
    @ObservedObject var setup: ExtensionSetup
    @ObservedObject private var settings = MenuSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().scaledToFit().frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.text("让右键菜单准备就绪")).font(.title2.bold())
                    Text(L10n.text("只需启用一次 Finder 扩展，即可开始使用。"))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 22) {
                step(1, title: "打开扩展设置", detail: "点击下方按钮，前往系统的扩展管理页面。")
                step(2, title: "开启 ZRightClick", detail: "在打开的列表中找到 ZRightClick，打开开关，然后返回这里。")
                step(3, title: "试试右键菜单", detail: "在 Finder 的普通文件夹空白处点按右键，即可新建文件、复制路径或打开终端。")
            }

            HStack(spacing: 10) {
                Image(systemName: setup.isEnabled ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundStyle(setup.isEnabled ? .green : .secondary)
                Text(L10n.text(setup.isEnabled ? "Finder 扩展已启用，可以开始使用了。" : "等待启用 Finder 扩展…"))
                    .font(.callout.weight(.medium))
                Spacer()
                Button(L10n.text("重新检测")) { setup.refresh() }.buttonStyle(.link)
            }
            .padding(14)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))

            Text(L10n.text("若未直接定位，请前往“通用 → 登录项与扩展”查找。不同 macOS 版本可能将此列表命名为“访达扩展”或“文件提供程序”。"))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(L10n.text("稍后设置")) { setup.isGuidePresented = false }
                Spacer()
                if setup.isEnabled {
                    Button(L10n.text("开始使用")) { setup.finish() }
                        .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                } else {
                    Button(L10n.text("打开系统设置")) { setup.openSystemSettings() }
                        .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(30)
        .frame(width: 540)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func step(_ number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(number)).font(.callout.bold())
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.12), in: Circle())
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.text(title)).font(.headline)
                Text(L10n.text(detail)).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
