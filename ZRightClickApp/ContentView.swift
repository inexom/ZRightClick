import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject private var settings = MenuSettings.shared
    @ObservedObject private var access = DirectoryAccessStore.shared
    @ObservedObject private var actions = FileActionController.shared
    @ObservedObject private var terminals = TerminalSettings.shared
    @ObservedObject private var extensionSetup = ExtensionSetup.shared
    @State private var customName = ""
    @State private var customSuffix = ""
    @State private var validationError: Error?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ZRightClick").font(.title2.bold())
                    Text(L10n.text("Finder 右键菜单增强")).foregroundStyle(.secondary)
                }
                Spacer()
                Button(L10n.text("扩展设置…")) {
                    extensionSetup.refresh()
                    extensionSetup.isGuidePresented = true
                }
            }
            if !extensionSetup.isEnabled {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                    Text(L10n.text("Finder 扩展未启用，右键菜单暂不可用。"))
                        .font(.callout)
                    Spacer()
                    Button(L10n.text("启用引导")) { extensionSetup.isGuidePresented = true }
                }
                .padding(12)
                .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }
            TabView(selection: $settings.selectedTab) {
                menuSettings.tabItem { Label(L10n.text("右键菜单"), systemImage: "cursorarrow.click") }.tag(MenuSettings.Tab.menus)
                fileTypes.tabItem { Label(L10n.text("文件类型"), systemImage: "doc.badge.plus") }.tag(MenuSettings.Tab.types)
                terminalSettings.tabItem { Label(L10n.text("终端"), systemImage: "terminal") }.tag(MenuSettings.Tab.terminal)
                authorization.tabItem { Label(L10n.text("目录授权"), systemImage: "folder.badge.person.crop") }.tag(MenuSettings.Tab.access)
            }
            Text(actions.status)
                .font(.callout).foregroundStyle(.secondary)
                .lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            HStack(alignment: .center, spacing: 20) {
                Text(L10n.text("关闭窗口后继续在菜单栏运行，可从菜单栏重新打开或退出。"))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Picker(selection: Binding(get: { settings.configuration.language ?? .initial }, set: { language in
                    settings.update { $0.language = language }
                })) {
                    Text("中文 (Chinese)").tag(AppLanguage.chinese)
                    Text("English").tag(AppLanguage.english)
                } label: {
                    Image(systemName: "globe").accessibilityLabel("Language / 语言")
                }
                .pickerStyle(.menu)
                .fixedSize()
                .accessibilityLabel("Language / 语言")
            }
        }
        .padding(24)
        .frame(minWidth: 620, minHeight: 540)
        .onAppear { extensionSetup.start() }
        .onDisappear { extensionSetup.stop() }
        .sheet(isPresented: $extensionSetup.isGuidePresented) {
            ExtensionSetupView(setup: extensionSetup)
        }
    }

    private var menuSettings: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(L10n.text("选择在 Finder 右键菜单中显示的功能。修改后自动保存，下次打开右键菜单时生效。"))
                .foregroundStyle(.secondary)
            menuToggle(L10n.text("新建文件"), detail: L10n.text("在文件夹空白处显示二级菜单，类型可在“文件类型”中勾选。"), key: \.newFileEnabled)
            menuToggle(L10n.text("复制路径"), detail: L10n.text("支持同时复制多个选中文件或文件夹的路径。"), key: \.copyPathEnabled)
            menuToggle(L10n.text("在此处打开终端"), detail: L10n.text("使用“终端”设置中选择的默认应用。"), key: \.terminalEnabled)
            Spacer()
            Text(L10n.text(extensionSetup.isEnabled ? "Finder 扩展已启用。" : "首次使用需在系统设置 → 通用 → 登录项与扩展 → 访达扩展中启用 ZRightClick。"))
                .font(.callout).foregroundStyle(.secondary)
        }.padding(20)
    }

    private func menuToggle(_ title: String, detail: String, key: WritableKeyPath<MenuConfiguration, Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(title, isOn: Binding(get: { settings.configuration[keyPath: key] }, set: { value in
                settings.update { $0[keyPath: key] = value }
            })).toggleStyle(.checkbox).font(.headline)
            Text(detail).font(.callout).foregroundStyle(.secondary).padding(.leading, 20)
        }
    }

    private var terminalSettings: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.text("选择“在此处打开终端”使用的应用，选择后自动保存。"))
                .foregroundStyle(.secondary)
            Picker(L10n.text("默认终端"), selection: Binding(get: { terminals.preferred }, set: { terminals.select($0) })) {
                ForEach(TerminalApplication.allCases) { application in
                    HStack {
                        terminalIcon(application)
                        Text(application.name + (terminals.installed[application] == nil ? L10n.text("（未安装）") : ""))
                    }.tag(application).disabled(terminals.installed[application] == nil)
                }
            }.pickerStyle(.menu)
            Divider()
            ForEach(TerminalApplication.allCases) { application in
                HStack(spacing: 10) {
                    terminalIcon(application)
                    Text(application.name)
                    Spacer()
                    Text(terminals.installed[application] == nil ? L10n.text("未安装") : L10n.text("已安装"))
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
            HStack {
                Button(L10n.text("选择文件夹并测试…")) { actions.testTerminal() }
                    .disabled(actions.isTestingTerminal)
                Button(L10n.text("刷新安装状态")) { terminals.refresh() }
            }
            if let notice = terminals.fallbackNotice {
                Text(notice).font(.callout).foregroundStyle(.orange)
            }
            Text(L10n.text("所选应用未安装或无法启动时，本次会改用系统终端，并保留你的选择。测试打开不会新增保存的目录授权。"))
                .font(.caption).foregroundStyle(.secondary)
            Text(L10n.text("第三方终端首次使用时，可能需要先完成其自身的初始设置。"))
                .font(.caption).foregroundStyle(.secondary)
            if !settings.configuration.terminalEnabled {
                Text(L10n.text("Finder 的“在此处打开终端”已关闭，仍可在这里配置和测试。"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }.padding(20).onAppear { terminals.refresh() }
    }

    private func terminalIcon(_ application: TerminalApplication) -> some View {
        Group {
            if let url = terminals.installed[application] {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path)).resizable().scaledToFit()
            } else {
                Image(systemName: "terminal").resizable().scaledToFit().foregroundStyle(.secondary)
            }
        }.frame(width: 20, height: 20)
    }

    private var fileTypes: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !settings.configuration.newFileEnabled {
                Text(L10n.text("“新建文件”菜单已关闭。以下配置会保留，重新启用后生效。"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.text("内置类型")).font(.headline)
                    ForEach(FileTypeDefinition.builtins) { type in
                        typeRow(type, enabled: Binding(get: {
                            !settings.configuration.disabledBuiltinIDs.contains(type.id)
                        }, set: { value in
                            settings.update {
                                if value { $0.disabledBuiltinIDs.remove(type.id) }
                                else { $0.disabledBuiltinIDs.insert(type.id) }
                            }
                        }), builtin: true)
                    }
                    Divider()
                    Text(L10n.text("自定义类型")).font(.headline)
                    if settings.configuration.customTypes.isEmpty {
                        Text(L10n.text("尚未添加。自定义类型会创建空文件，例如 js、py、json。"))
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    ForEach(settings.configuration.customTypes) { custom in
                        typeRow(custom.definition, enabled: Binding(get: {
                            settings.configuration.customTypes.first(where: { $0.id == custom.id })?.enabled ?? false
                        }, set: { value in
                            settings.update { config in
                                if let index = config.customTypes.firstIndex(where: { $0.id == custom.id }) {
                                    config.customTypes[index].enabled = value
                                }
                            }
                        }), builtin: false)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            Divider()
            HStack {
                TextField(L10n.text("名称（可选）"), text: $customName)
                TextField(L10n.text("后缀，例如 js"), text: $customSuffix).frame(width: 145)
                    .onSubmit(addCustomType)
                Button(L10n.text("添加"), action: addCustomType).disabled(customSuffix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if let validationError {
                Text(validationError.localizedDescription).font(.caption).foregroundStyle(.red)
            }
            Text(L10n.text("内置类型只能启用或停用。Office 类型使用空白模板，无需安装 Office 即可创建；创建后在 Finder 中选中，不自动打开。"))
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20)
    }

    private func typeRow(_ type: FileTypeDefinition, enabled: Binding<Bool>, builtin: Bool) -> some View {
        HStack(spacing: 10) {
            Toggle(isOn: enabled) {
                HStack(spacing: 10) {
                    Image(nsImage: type.icon).frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(type.title)
                        if ["docx", "xlsx", "pptx"].contains(type.id) {
                            Text(defaultApplication(for: type.suffix)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }.toggleStyle(.checkbox)
            Spacer()
            if builtin {
                Text(L10n.text("内置")).font(.caption).foregroundStyle(.secondary)
            } else {
                Button(L10n.text("删除")) { settings.update { $0.customTypes.removeAll { $0.id == type.id } } }
            }
        }
    }

    private func defaultApplication(for suffix: String) -> String {
        guard let type = UTType(filenameExtension: suffix),
              let application = NSWorkspace.shared.urlForApplication(toOpen: type) else {
            return L10n.text("未找到默认打开应用，仍可创建文件")
        }
        return L10n.text("默认打开：%@", application.deletingPathExtension().lastPathComponent)
    }

    private func addCustomType() {
        do {
            try settings.add(name: customName, suffix: customSuffix)
            customName = ""
            customSuffix = ""
            validationError = nil
        } catch { validationError = error }
    }

    private var authorization: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.text("打开终端使用只读授权，新建文件需要读写授权。首次操作时选择目标目录或它的上级目录，之后可复用授权。"))
                .font(.callout).foregroundStyle(.secondary)
            if access.grants.isEmpty {
                ContentUnavailableView(L10n.text("尚未授权目录"), systemImage: "folder", description: Text(L10n.text("使用 Finder 右键功能时会按需请求授权。")))
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(access.grants) { grant in
                            HStack {
                                Image(systemName: "folder").foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(grant.path).textSelection(.enabled)
                                    Text(grant.writable == true ? L10n.text("读写") : L10n.text("只读"))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(L10n.text("移除")) { access.remove(grant.id) }
                            }
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            Text(L10n.text("移除后应用不再复用该授权。原有只读授权会保留，新建文件时需要额外确认写入权限。"))
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20)
    }
}

#Preview { ContentView() }
