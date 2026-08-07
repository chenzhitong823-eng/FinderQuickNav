# man导（FinderQuickNav）

一个 macOS Finder 效率工具：在文件夹空白处右键，即可弹出低遮挡的快速导航卡片，完成“返回上一位置、上层文件夹、路径层级跳转、收藏、最近访问、收藏当前位置”，同时保留独立的“新建文件”右键入口。

## 功能

- Finder 空白处右键 → “快速导航”弹出低遮挡卡片，卡片贴近右键位置并自动避让文件
- 收藏 / 最近访问分页显示，导航后保持当前分页
- 悬停路径行显示完整路径与路径层级按钮，点击路径任意位置复制当前文件夹路径
- 宿主后台常驻（不占 Dock）：应用未运行时，右键可自动拉起并直接弹出卡片
- 独立“新建文件”右键菜单：文件夹、TXT、Markdown、Word、Excel、PowerPoint（冲突安全命名）
- 平铺式设置窗口：快速导航、个人收藏、新建文件、权限与扩展
- 菜单栏房子图标入口（打开设置 / 退出）

## 环境要求

- macOS 14.0 或更高（开发机为 macOS 15.7.2，Apple Silicon）
- Xcode 16.4（Swift 6）
- XcodeGen 2.46.0（生成工程，可选，仓库已含生成的 `.xcodeproj`）

## 构建与安装

本机开发签名（无开发者账号）：

```bash
cd FinderQuickNav
scripts/build-local.sh        # 生成 build-local/FinderQuickNav.app
scripts/install-local.sh      # 安装到 ~/Applications 并注册 Finder 扩展
```

首次使用需要在“系统设置 → 隐私与安全性”中授权：

- 辅助功能（导航用快捷键返回/上一级）
- 自动化（控制 Finder）
- 完全磁盘访问（可选，授权后进入任何文件夹都不再弹权限询问）

## 技术架构

- **Finder Sync Extension**：提供空白处右键菜单，读取当前目录和鼠标坐标
- **宿主 App**（`LSUIElement` 后台代理）：承载非激活 `NSPanel` 卡片、导航、存储与新建文件服务
- **通信**：扩展到宿主使用 `DistributedNotificationCenter + Codable JSON` 瞬时事件；App Group 共享待处理请求与菜单偏好
- **导航**：目录跳转使用 Finder Apple Event，返回/上一级使用辅助功能键盘事件，动作前先确认 Finder 前台

## 测试

```bash
cd FinderQuickNav
for t in scripts/test-*.sh; do zsh "$t"; done
```

每个功能模块都有独立 smoke test；Finder 集成需在真实 Finder 空白处右键验收。

## 许可证

MIT License，详见 [LICENSE](LICENSE)。
