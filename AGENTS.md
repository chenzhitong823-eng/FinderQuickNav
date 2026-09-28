# AGENTS.md

## Project overview

本项目设计并实现一个 macOS Finder 效率工具。当前已选定“方案 C：低遮挡弹出卡片”，在 Finder 文件夹空白处右键后提供“快速导航”和“新建文件”入口。

## Environment

- 当前机器：Apple Silicon，macOS 15.7.2。
- 已安装并选中 Xcode 16.4（Build 16F6），路径 `/Users/mac/Applications/Xcode-16.4.0.app`；Swift 6.1.2。
- 原型使用原生 HTML、CSS、JavaScript，无第三方依赖。
- 正式版本计划使用 Swift 6、SwiftUI、AppKit 和 Finder Sync Extension。

## Setup commands

- 原型阶段不需要安装依赖。
- 正式开发前安装 Xcode 16.4 或更高的兼容版本，并运行 `xcodebuild -version` 验证。
- 不要为了生成工程主动安装额外项目生成器；先使用 Xcode 原生 macOS App 与 Finder Sync Extension 模板。

## Run commands

- 打开原型总览：`open work/prototypes/index.html`
- 打开已选原型：`open work/prototypes/variant-c.html`
- 本机 App Group 开发构建：`zsh FinderQuickNav/scripts/build-local.sh`；Release：`FQN_CONFIGURATION=Release zsh FinderQuickNav/scripts/build-local.sh`。
- Xcode 直签需要开发者 provisioning profile；当前本机没有 profile，因此使用脚本先无签名构建，再用现有本地证书重签 App 和 Extension。
- 手工注册 Finder 扩展时，传入 `FinderQuickNav.app/Contents/PlugIns/FinderQuickNavExtension.appex`，不要只传 App 外层目录。

## Test commands

- 全量回归统一使用 `zsh FinderQuickNav/scripts/run-tests.sh`；可用 `FQN_TEST_LOG_DIR` 保存逐项日志，失败必须返回非零退出码。
- 原型脚本语法检查：用已登记的 Node.js 读取 HTML 中的 `<script>` 并通过 `new Function(...)` 编译。
- 正式工程创建后：`xcodebuild test -scheme FinderQuickNav -destination 'platform=macOS'`。
- Finder 集成必须在真实 Finder 空白区域右键验收，不能只依赖单元测试。

## Code style

- Swift 6，优先值类型、协议隔离和依赖注入。
- 每个文件只承担一个职责；面板定位、导航、权限、收藏、新建文件分开实现。
- 不引入第三方依赖，除非已有方案无法达成核心需求并获得用户确认。

## Important files

- `CONTEXT.md`：项目事实和共享语言。
- `docs/任务进程.md`：跨模型续作入口，后续模型先读它。
- `docs/superpowers/specs/2026-08-06-finder-quick-nav-design.md`：产品与技术规格。
- `docs/superpowers/plans/2026-08-06-finder-quick-nav.md`：DeepSeek 执行计划。
- `work/prototypes/variant-c.html`：已选的低遮挡可交互原型。
- `FinderQuickNav/App/Settings/SettingsView.swift`：平铺式设置窗口。
- `FinderQuickNav/Shared/NewFilePreferencesStore.swift`：宿主和 Finder 扩展共享新建入口配置。
- `FinderQuickNav/scripts/build-local.sh`：本机 App Group 构建和重签入口。

## Common pitfalls

- 安装路径使用当前用户主目录或 `FQN_INSTALL_DIR`；禁止把开发机用户名写死到安装脚本。
- `pluginkit` 只有一个注册项不等于可用：还必须已启用且指向预期完整路径；安装更新后须检查真实菜单是否缓存了旧扩展实例。
- 请求去重缓存必须按时间顺序淘汰，不能用无序 `Set.removeFirst()` 代替 FIFO，否则近期请求可能重复执行。
- `NSRunningApplication.activate` 成功表示激活请求获准，不保证前台已同步切换；明确发给 Finder 的 Apple Event 与全局键盘事件须分别处理。
- Finder Sync 只在已监控目录及其子目录中提供菜单；首版默认覆盖用户主目录。
- `.contextualMenuForContainer` 才是 Finder 空白处右键，不要误用文件项菜单。
- Finder Sync 不是通用 Finder UI 注入框架，卡片应由宿主应用的非激活 `NSPanel` 承载。
- Finder Sync 可能同时为 Finder 和打开/保存面板创建多个扩展进程，不要在扩展内保存复杂状态。
- 同一个 bundle ID 可能残留多个 build 副本；部署前运行 `scripts/verify-extension-registration.sh`，必须只剩一个注册项。
- 即使 Finder 扩展只注册一项，归档目录中同 bundle ID 的旧宿主仍可能作为运行进程干扰“宿主是否已启动”的判断；`HostSessionEnsurer` 必须比较扩展所属 `.app` 的规范化完整路径，不能只按 bundle ID 判定。
- App Group entitlement 在没有 provisioning profile 时会让普通 `xcodebuild build` 直接失败；不要删除 entitlement，应使用 `scripts/build-local.sh`，并把这个限制写入交接记录。
- 返回、上一级、当前窗口跳转需要真实 Finder 权限与集成验证。
- 原生工程必须通过实际 `xcodebuild` 后才能声称可以构建。

## User preferences

- 已确定采用方案 C。
- 卡片必须贴近右键位置，但优先降低对文件图标的遮挡。
- 收藏与最近访问分页显示；新建文件保留为独立右键入口。
- 目录跳转应尽量发生在当前 Finder 窗口，不额外打开窗口。
- 后续由 DeepSeek 接续时，直接读取 `docs/任务进程.md` 并执行第一条未完成任务。

## Do not do

- 不要重新比较 A/B/C 或重新规划已确定的方向。
- 不要删除 A/B 原型，它们保留为决策依据。
- 不要在未经验证时承诺覆盖所有外接磁盘、所有打开/保存对话框或 App Store 上架。
- 不要自动安装 Xcode、申请开发者账号、提交 App Store、签名或公证。
- 不要用会默认打开新 Finder 窗口的方案替代“当前窗口跳转”而不说明降级。
