<div align="center">
  <img src="Design/AppIcon-master.png" width="112" alt="ZRightClick 应用图标">
  <h1>ZRightClick</h1>
  <p><strong>常用操作，右键即达。</strong></p>
  <p>新建文件、复制路径、打开终端，让 Finder 更顺手。</p>
  <p>
    <img src="https://img.shields.io/badge/macOS-15%2B-111827?logo=apple&logoColor=white" alt="macOS 15 及以上">
    <img src="https://img.shields.io/badge/Built_with-Swift-F05138?logo=swift&logoColor=white" alt="使用 Swift 构建">
    <img src="https://img.shields.io/badge/UI-English_%2F_简体中文-5266EB" alt="英文与简体中文">
  </p>
  <p><strong>简体中文</strong> · <a href="README.en.md">English</a></p>
  <p><a href="#功能">功能</a> · <a href="https://github.com/inexom/ZRightClick/releases/latest">下载</a> · <a href="#开始使用">开始使用</a> · <a href="docs/DEVELOPMENT.md">开发文档</a> · <a href="https://github.com/inexom/ZRightClick/issues">问题反馈</a></p>
</div>

---

ZRightClick 是一款原生 macOS Finder 右键增强工具，专注于日常文件操作。选好需要的菜单、文件类型和终端，关闭设置窗口后，它会安静地留在菜单栏中。

> **项目状态：** 已提供 1.0 通用版下载（Apple 芯片 + Intel）。当前使用临时签名，**未经 Apple 公证**；尚未提供 Developer ID 正式签名版或 Mac App Store 版本。源码公开**不代表授予软件使用许可**，详见[使用与版权](#使用与版权)。

## 功能

| 功能 | 使用体验 |
| --- | --- |
| **新建文件** | 两级右键菜单，内置 `.txt`、`.md`、`.docx`、`.xlsx`、`.pptx`，附带类型图标。 |
| **自定义文件类型** | 添加 `.js`、`.py`、`.json`、`.d.ts` 等后缀来创建空文件。内置类型可勾选启用，自定义类型可添加、停用或删除。 |
| **复制路径** | 一次复制多个选中文件或文件夹的路径。 |
| **在此处打开终端** | 自选系统 Terminal、iTerm2、Ghostty 或 Warp；显示安装状态，所选终端不可用时，本次回退系统终端。 |
| **菜单栏常驻** | 关闭设置窗口后隐藏 Dock 图标，应用继续运行。从菜单栏重新打开设置或真正退出。 |
| **中英文切换** | 中文与 English 即时切换，自动保存选择，并同步到 Finder 扩展。 |

三个一级菜单都有独立开关。设置自动保存，下次打开右键菜单时生效。

## 原生设置界面

<p align="center">
  <img src="docs/images/settings-zh-CN.png" width="720" alt="ZRightClick 中文设置界面，包含独立菜单开关和右下角语言选择器">
</p>

应用使用 **SwiftUI + AppKit**，右键菜单由 **FinderSync 扩展**提供，没有第三方软件包依赖。

## 开始使用

### 下载 1.0

[**下载 DMG 安装包**](https://github.com/inexom/ZRightClick/releases/download/v1.0/ZRightClick-1.0-universal.dmg) · [ZIP 压缩包](https://github.com/inexom/ZRightClick/releases/download/v1.0/ZRightClick-1.0-universal.zip) · [更新说明与校验值](https://github.com/inexom/ZRightClick/releases/tag/v1.0)

1. 打开 DMG，将 **ZRightClick.app** 拖入**应用程序**。使用 ZIP 时，解压后将应用移入应用程序目录。
2. 从应用程序目录启动，再按下文启用 Finder 扩展。
3. 当前版本**未经 Apple 公证**。如果 macOS 阻止打开，请先确认下载来源与校验值，再参考 [Apple 官方打开说明](https://support.apple.com/zh-cn/102445)，在可用时前往**系统设置 → 隐私与安全性 → 仍要打开**。

同一安装包包含 **arm64 和 x86_64**，支持 Apple 芯片与 Intel Mac，要求 macOS 15 及以上。原位替换同一应用时会保留已有设置和目录授权。

### 环境要求

- **运行：** macOS 15 及以上。
- **构建：** Xcode、macOS SDK 与命令行工具。当前工程已在 **Xcode 27.0 beta** 上验证，旧版 Xcode 尚未验证。
- **模板检查：** Python 3。应用运行本身不依赖 Python。

### 本地构建安装

```sh
git clone https://github.com/inexom/ZRightClick.git
cd ZRightClick
./scripts/dev.sh
```

脚本会编译 **Release** 版本、替换 `/Applications/ZRightClick.app`、注册 Finder 扩展、启动应用，并**重启 Finder**。构建失败时会停止，不会安装旧产物。这是本地开发安装流程，并非正式签名的分发安装包。

也可以用 Xcode 打开 `ZRightClick.xcodeproj`，选择 **ZRightClick** scheme。仅编译的命令、签名说明和检查方式见[开发文档](docs/DEVELOPMENT.md)。

### 启用 Finder 扩展

1. 在**系统设置 → 通用 → 登录项与扩展 → 访达扩展**中启用 **ZRightClick**。不同 macOS 版本的名称可能略有差异。
2. 打开 ZRightClick，勾选希望显示的右键功能。
3. 在普通文件夹空白处右键使用**新建文件**；选中文件或文件夹后，可复制路径或打开对应位置的终端。
4. 首次执行文件或终端操作时，在系统弹窗中选择目标文件夹或它的上级目录。

授权会保存供后续复用。新建文件需要**读写**权限，打开终端可使用**只读**权限。在**目录授权**页可以查看或移除已保存的授权。

## 一些使用细节

### 文件类型与命名

- Office 文档使用应用自带的空白模板，**无需安装 Microsoft Office 即可创建**。后续打开文档需要兼容的软件。
- 中文界面默认创建 `未命名.ext`，英文界面创建 `Untitled.ext`。重名时自动编号，不覆盖已有文件、目录或符号链接。
- 创建后在 Finder 中选中文件，不自动打开编辑器。按 **Return** 即可重命名。
- 自定义后缀创建空文件。PDF、图片、旧版 Office 等已知需要特定结构的格式，不能作为自定义空文件添加。

### 终端由你选择

在**终端**设置中选择默认应用。全新安装默认使用系统 Terminal，页面会显示各终端的安装状态，也可以选择文件夹测试打开；测试不会新增保存的目录授权。

如果所选终端已被移除或启动请求失败，本次会尝试系统 Terminal，同时保留你的偏好。第三方终端首次使用时，可能需要先完成它自己的初始设置。

### 授权与控制

主应用和 Finder 扩展均保留 **App Sandbox**。扩展把固定操作和路径转交给主应用，由主应用通过系统文件夹选择器请求权限，并保存安全作用域书签。

打开终端通过应用 URL 实现，不生成 shell 命令，也不请求 Apple Events 自动化权限。已保存的目录授权可以在设置中移除。语言切换作用于应用自身的文案；系统文件选择器中的控件仍由 macOS 决定语言。

## 常见问题

<details>
<summary><strong>Finder 右键菜单没有出现怎么办？</strong></summary>

确认系统设置中已启用 Finder 扩展、应用内对应开关已打开，然后关闭并重新展开右键菜单。请先在普通文件夹中测试，避免搜索等虚拟视图。开发安装问题可运行 `./scripts/dev.sh status`，并查看[排查说明](docs/DEVELOPMENT.md#troubleshooting)。

</details>

<details>
<summary><strong>每次使用都需要重新授权吗？</strong></summary>

正常情况下不需要。应用会保存安全作用域书签，在需要时恢复授权，包括主应用退出后的再次使用。授权失效或被移除时可能需要重新选择目录。已有只读授权不会自动升级为写入权限。

</details>

<details>
<summary><strong>关闭窗口是不是退出应用？</strong></summary>

不是。关闭窗口会释放设置界面、隐藏 Dock 图标，同时保留菜单栏入口。选择**退出 ZRightClick**才会停止主应用。Finder 扩展由 macOS 单独管理，之后的 Finder 文件操作仍可重新唤起主应用。

</details>

<details>
<summary><strong>所有终端都经过完整实测了吗？</strong></summary>

系统 Terminal、iTerm2 和 Ghostty 已进行本机测试。Warp 的启动请求已成功，但首次设置之后的实际 shell 工作目录尚未确认。当前验证范围与限制见[开发文档](docs/DEVELOPMENT.md#validation-scope)。

</details>

## 开发与反馈

运行 Foundation 层测试和 Office 模板检查：

```sh
./scripts/test.sh
```

[开发文档](docs/DEVELOPMENT.md)介绍了架构、本地构建、Finder 手动验证和已知限制。欢迎通过 [GitHub Issues](https://github.com/inexom/ZRightClick/issues)反馈问题、提出功能建议或改进翻译。

## 使用与版权

Copyright © 2026 [inexom](https://github.com/inexom)。保留所有权利。

当前**未授予软件许可（No license）**。源码公开不代表授权他人使用、修改、再分发或商业化；其他人的商业使用需要取得版权所有者许可。GitHub 平台提供的公开仓库查看与 fork 权利仍依其服务条款执行。参见 [GitHub 关于无许可证仓库的说明](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)。
