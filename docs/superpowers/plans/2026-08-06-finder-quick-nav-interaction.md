# Finder QuickNav 交互与设置增量实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复方案 C 卡片的拖动、生命周期、路径和整行点击体验，并加入可管理快速导航、个人收藏和新建文件入口的原生设置窗口。

**Architecture:** 保留 Finder Sync Extension 作为右键菜单入口，宿主继续使用非激活 NSPanel。把面板交互状态、共享偏好和设置窗口分别隔离；收藏和最近访问由宿主读取，菜单可见性偏好通过 App Group UserDefaults 与扩展共享。

**Tech Stack:** Swift 6、SwiftUI、AppKit、Finder Sync、Foundation、XCTest 风格 smoke test、原生 HTML/CSS/JavaScript 原型；不引入第三方依赖。

## Global Constraints

- 方案 C 已确定，卡片必须低遮挡且贴近右键位置。
- 不重做已通过的 bridge、导航、基础收藏、最近访问和新建文件底层服务。
- 不加入“发送到”、复制/移动文件、云同步和 App Store 发布。
- 原生功能只有 fresh build 和回归脚本通过后才能声称可构建。
- 不自动签名、公证、提交 Git 或替换用户未确认的部署副本。

## 文件职责

- `App/QuickNavPanelController.swift`：面板生命周期、拖动属性、外部点击监视、连续导航状态和卡片刷新。
- `App/QuickNavPathModel.swift`：规范化路径摘要、完整路径和路径组件。
- `App/QuickNavPathView.swift`：紧凑路径摘要、悬停完整路径和路径段回调。
- `App/Settings/QuickNavPreferences.swift`：共享配置模型、App Group UserDefaults 编解码和默认值。
- `App/Settings/SettingsWindowController.swift`：设置窗口生命周期和模块路由。
- `App/Settings/SettingsView.swift`：左侧模块列表及快速导航、收藏、新建文件、权限页面。
- `App/Storage/FavoritesStore.swift`：收藏显示名、启用状态和顺序更新。
- `Shared/NewFilePreferencesStore.swift`：六种新建文件入口的启用状态和顺序，供宿主和扩展共同读取。
- `Extension/FinderSync.swift`：读取共享新建文件偏好，构造当前 Finder 菜单。
- `App/FinderQuickNavApp.swift` / `App/AppDelegate.swift`：设置窗口入口和应用生命周期。
- `App/FinderQuickNav.entitlements` / `Extension/FinderQuickNavExtension.entitlements` / `project.yml`：App Group 配置。
- `Tests/*SmokeTest/main.swift` 与 `scripts/test-*.sh`：纯模型和策略回归，不依赖 Finder UI。
- `work/prototypes/variant-c.html`：原生实现同步的浏览器交互原型。

---

### Task 1: 共享偏好和收藏编辑模型

**Files:**
- Create: `FinderQuickNav/App/Settings/QuickNavPreferences.swift`
- Create: `FinderQuickNav/Shared/NewFilePreferencesStore.swift`
- Modify: `FinderQuickNav/App/Storage/FolderEntry.swift`
- Modify: `FinderQuickNav/App/Storage/FavoritesStore.swift`
- Create: `FinderQuickNav/Tests/SettingsPreferencesSmokeTest/main.swift`
- Create: `FinderQuickNav/scripts/test-settings-preferences.sh`

**Interfaces:**
- `QuickNavPreferencesStore` 提供 `preferences`、`update(_:)`，默认使用 `UserDefaults(suiteName: "group.local.finderquicknav")`。
- `FavoritesStore` 提供 `rename(path:displayName:)`、`setEnabled(path:_:) `、`move(path:to:)`。
- `NewFilePreferencesStore` 提供 `entries`、`setEnabled(action:_:) `、`move(action:to:)`。

- [x] **Step 1: 写失败测试**：用独立 UserDefaults suite 断言默认“导航后保持打开”；收藏改名、排序和去重；六种新建动作默认启用，关闭 Word 后重新读取仍关闭。
- [x] **Step 2: 运行失败测试**：运行 `zsh FinderQuickNav/scripts/test-settings-preferences.sh`，确认因新类型和编辑方法不存在而失败。
- [x] **Step 3: 实现最小模型**：配置只包含 `keepPanelOpenAfterNavigation`、`showFullPathOnHover`、`defaultTab` 和 enabled actions；路径用规范化本地路径作为稳定 ID，显示名与 URL 分离。
- [x] **Step 4: 运行通过测试**：同一脚本输出 `settings preferences smoke test passed` 后记录到任务进程。

### Task 2: 面板生命周期和连续导航

**Files:**
- Modify: `FinderQuickNav/App/QuickNavPanelController.swift`
- Modify: `FinderQuickNav/App/Navigation/FinderNavigator.swift`
- Modify: `FinderQuickNav/App/Navigation/AppleEventFinderWindowController.swift`
- Modify: `FinderQuickNav/Tests/FinderNavigationSmokeTest/main.swift`

**Interfaces:**
- 面板私有职责：`installEventMonitors()`、`removeEventMonitors()`、`refreshCurrentDirectory()`。
- `FinderWindowControlling` 增加 `currentTarget() throws -> URL`，Apple Event 控制器实现该方法。

- [x] **Step 1: 写失败回归测试**：扩展现有导航 mock 的 `currentTarget()`；增加纯状态断言，成功导航后 `isPresented` 仍为真并更新目录，外部点击才变为假。
- [x] **Step 2: 运行失败测试**：运行 `zsh FinderQuickNav/scripts/test-finder-navigation-policy.sh`，确认旧协议/旧收起行为无法满足新增断言。
- [x] **Step 3: 实现面板生命周期**：设置 `isMovable = true`、`isMovableByWindowBackground = true`；显示时注册本地/全局鼠标监视器，事件位置不在 `panel.frame` 内就关闭，关闭时移除 token；成功导航后刷新消息和视图，不调用 `orderOut`。
- [x] **Step 4: 实现实际 target 刷新**：返回/上层键盘事件后短延迟读取 Finder target；读取失败保留原目录并显示错误。
- [x] **Step 5: 运行回归**：运行导航策略、桥接、存储和定位脚本，确保已有行为不退化。

### Task 3: 路径悬停、整行命中和动画

**Files:**
- Create: `FinderQuickNav/App/QuickNavPathModel.swift`
- Create: `FinderQuickNav/App/QuickNavPathView.swift`
- Modify: `FinderQuickNav/App/QuickNavPanelController.swift`
- Create: `FinderQuickNav/Tests/PathDisplaySmokeTest/main.swift`
- Create: `FinderQuickNav/scripts/test-path-display.sh`
- Modify: `work/prototypes/variant-c.html`

**Interfaces:**
- `FolderPathDisplay` 提供 `compactLabel`、`fullPath`、`components`。
- `QuickNavPathView` 接收 `directoryURL`、`showFullPathOnHover` 和 `onNavigate(URL)`。

- [x] **Step 1: 写失败测试**：对 `/Users/mac/Documents/Codex` 断言默认摘要为 `Codex`，完整路径和组件顺序正确，根目录摘要不为空。
- [x] **Step 2: 运行失败测试**：运行 `zsh FinderQuickNav/scripts/test-path-display.sh`，确认缺少 `FolderPathDisplay` 时失败。
- [x] **Step 3: 实现路径视图**：默认显示房子图标和当前目录名；悬停时显示 material 完整路径气泡；路径段使用整段按钮回调导航；不改变卡片固定高度。
- [x] **Step 4: 改造目录行**：按钮 label 使用全宽 frame、`contentShape(Rectangle())` 和自定义 hover/pressed 样式；将“返回”改为“上一位置”，“上一级”改为“上层文件夹”；分页和路径使用短时 easeInOut 过渡。
- [x] **Step 5: 同步浏览器原型**：加入拖动标题、完整路径 hover、整行蓝色选中、导航不收起和外部关闭；保留独立新建文件右键入口。
- [x] **Step 6: 运行测试**：运行路径脚本和 Node.js HTML script compile check，记录实际输出。

### Task 4: 设置窗口和应用入口

**Files:**
- Create: `FinderQuickNav/App/Settings/SettingsWindowController.swift`
- Create: `FinderQuickNav/App/Settings/SettingsView.swift`
- Modify: `FinderQuickNav/App/FinderQuickNavApp.swift`
- Modify: `FinderQuickNav/App/AppDelegate.swift`
- Modify: `FinderQuickNav/App/QuickNavPanelController.swift`

**Interfaces:**
- `SettingsWindowController.shared.show(section:)` 打开或复用设置窗口。
- `SettingsSection` 枚举包含 `.quickNavigation`、`.favorites`、`.newFiles`、`.permissions`。

- [x] **Step 1: 写入口回归测试**：断言“管理收藏”路由到 `.favorites`，首批设置项只包含快速导航、个人收藏、新建文件和权限，不提供可用“发送到”动作。
- [x] **Step 2: 运行失败测试**：先观察到路由类型缺失导致红灯，再实现最小入口并回归通过。
- [x] **Step 3: 创建窗口**：用约 760×500 的可调整大小 NSWindow + NSHostingView；左侧模块列表、右侧编辑区域；单例复用，重复打开只切换 section。
- [x] **Step 4: 实现编辑页**：快速导航编辑偏好；收藏页实现添加目录、显示名编辑、排序、启用/停用、删除；新建文件页实现六种入口启用/停用和排序；视图只调用 stores。
- [x] **Step 5: 接入入口**：卡片 footer 调用 `show(section: .favorites)`；应用设置入口调用 `.quickNavigation`；移除 `EmptyView()` 设置壳。
- [x] **Step 6: Debug build**：宿主和扩展通过本机无 provisioning profile 的 fresh Debug build，并由本地脚本完成重签。

### Task 5: App Group 和扩展菜单配置

**Files:**
- Create: `FinderQuickNav/App/FinderQuickNav.entitlements`
- Create: `FinderQuickNav/Extension/FinderQuickNavExtension.entitlements`
- Modify: `FinderQuickNav/project.yml`
- Modify: `FinderQuickNav/Extension/FinderSync.swift`

**Interfaces:**
- App 和 Extension 共享 `group.local.finderquicknav`。
- Extension 读取 `NewFilePreferencesStore` 的 enabled 状态和顺序。

- [x] **Step 1: 写共享配置失败测试**：同一 suite 创建宿主和扩展 store，关闭 Word 后断言共享读取状态、其他动作顺序不变。
- [x] **Step 2: 运行失败测试**：先以缺少共享 store/entitlement 接口为红灯边界，再实现共享配置。
- [x] **Step 3: 配置 entitlements**：两个 target 声明 `com.apple.security.application-groups` 的 `group.local.finderquicknav`，XcodeGen 分别指向两个 entitlements 文件，保持扩展沙盒策略。
- [x] **Step 4: 改造右键菜单**：按 enabled/order 生成新建文件子菜单；全部关闭时不添加父项，至少一项启用时按设置顺序添加。
- [x] **Step 5: 构建回归**：App Group 静态检查、本机 Debug/Release 构建、重签和单一扩展注册检查通过；普通 Xcode 直签仍需 provisioning profile。

### Task 6: 完整验收和记录

**Files:**
- Create: `FinderQuickNav/docs/interaction-verification.md`
- Modify: `docs/任务进程.md`
- Modify: `docs/决策日志.md`
- Modify: `docs/进度报告.md`
- Modify: `CONTEXT.md`

- [x] **Step 1: 运行纯模型回归**：settings、path、navigation、folder stores、bridge、new-file、placement、App Group 和扩展注册脚本全部通过；原型脚本编译和输出同步检查通过。
- [x] **Step 2: fresh Debug/Release build**：通过 `scripts/build-local.sh` 完成 Debug/Release 无签名构建、App Group 重签和深度签名验证；直签失败原因已记录。
- [ ] **Step 3: 真实 Finder 验收**：已验证卡片显示、文案、连续上层/上一位置、设置窗口和模块切换；拖动手势、面板外关闭、路径 hover、空白行命中和清理重复扩展后的菜单刷新仍待一次稳定现场复测。
- [ ] **Step 4: 更新交接记录**：任务进程已更新；交接、决策和进度文档需在本轮最终记录后同步，双屏、长时 Instruments、签名发布和“发送到”继续保留。

## 工具利用检查

- 本任务可用工具：Xcode 16.4、Swift 6.1、Node.js 22、现有 smoke scripts、浏览器原型。
- 已使用工具：现状审查、Node.js 原型语法检查、Xcode 构建/脚本回归、公开产品页面功能对照。
- 未使用但可考虑工具：Instruments、真实 Finder 多屏验收；只在对应阶段使用。
- 是否需要安装新工具：不需要。
- 安装原因：无。
- 安装后如何验证：无新增安装。
- 安装后如何复用：复用现有 Node.js 和 Xcode 工具链。
- 是否已写入工具资产台账：不新增工具，不修改台账。
