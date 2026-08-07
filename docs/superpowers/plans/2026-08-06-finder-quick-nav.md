# Finder QuickNav Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个 macOS Finder 扩展，在文件夹空白处右键后显示“快速导航”和“新建文件”，并用低遮挡非激活卡片在当前 Finder 窗口完成导航。

**Architecture:** Finder Sync Extension 只提供背景右键菜单、当前目录和触发请求；宿主应用负责非激活 `NSPanel`、卡片 UI、定位、收藏、最近访问、新建文件、Finder 导航和权限。第一阶段先验证扩展到宿主的桥接和当前 Finder 窗口控制，只有验证通过才进入完整功能。

**Tech Stack:** macOS 15.7.2 验证机、Xcode 16.4+、Swift 6、SwiftUI、AppKit、FinderSync、XCTest；不使用第三方依赖。

## Global Constraints

- 选定方案 C，不重新比较 A/B/C。
- 卡片目标尺寸 `292 × 286 pt`，收藏与最近访问一次只显示一组。
- 位置必须依据鼠标、屏幕和 Finder 窗口边界自动避让；无法读取窗口时使用屏幕四象限降级。
- “新建文件”是独立背景右键子菜单，不塞进快速导航卡片。
- 导航尽量作用于原 Finder 窗口，不默认打开新窗口。
- 首版只承诺当前用户主目录及其子目录。
- 最近访问只记录打开卡片时的当前目录和通过本工具完成的跳转。
- 宿主空闲和扩展空闲时不得持续轮询 Finder。
- 当前未安装完整 Xcode；不得在安装和真实构建前声称原生版本可运行。
- 未经用户明确要求，不执行 Git commit、签名发布、公证或 App Store 提交。

---

## Planned File Structure

```text
FinderQuickNav/
├── FinderQuickNav.xcodeproj/
├── App/
│   ├── FinderQuickNavApp.swift
│   ├── AppDelegate.swift
│   ├── Info.plist
│   ├── Models/
│   │   ├── QuickNavRequest.swift
│   │   └── FolderEntry.swift
│   ├── Panel/
│   │   ├── QuickNavPanelController.swift
│   │   ├── QuickNavView.swift
│   │   └── PanelPlacementEngine.swift
│   ├── Navigation/
│   │   ├── FinderNavigator.swift
│   │   └── FinderWindowReader.swift
│   ├── Permissions/
│   │   └── PermissionCenter.swift
│   ├── Storage/
│   │   ├── FavoritesStore.swift
│   │   └── RecentsStore.swift
│   └── NewFile/
│       ├── NewFileService.swift
│       └── Templates/{blank.docx,blank.xlsx,blank.pptx}
├── Extension/
│   ├── FinderSync.swift
│   ├── ExtensionRequestBridge.swift
│   ├── Info.plist
│   └── FinderQuickNavExtension.entitlements
├── Shared/
│   ├── QuickNavAction.swift
│   └── URLRequestCodec.swift
├── Tests/
│   ├── URLRequestCodecTests.swift
│   ├── PanelPlacementEngineTests.swift
│   ├── FavoritesStoreTests.swift
│   ├── RecentsStoreTests.swift
│   ├── FinderNavigatorTests.swift
│   └── NewFileServiceTests.swift
└── docs/
    ├── feasibility-results.md
    ├── permissions.md
    └── verification.md
```

---

### Task 1: 开发环境与 Finder 集成可行性闸门

**Files:**
- Create: `FinderQuickNav/docs/feasibility-results.md`
- Create: `FinderQuickNav/Spike/FinderQuickNavSpikeApp.swift`
- Create: `FinderQuickNav/Spike/FinderSync.swift`

**Interfaces:**
- Consumes: 当前 macOS、Finder Sync 和系统扩展管理。
- Produces: 明确的桥接结论 `custom-url` 或 `app-group`，以及当前窗口导航可行性结论。

- [ ] **Step 1: 验证完整 Xcode**

Run:

```bash
xcodebuild -version
xcrun swift --version
```

Expected: `Xcode 16.4` 或更高兼容版本；如果仍显示 Command Line Tools 错误，停止正式工程创建，提示用户安装完整 Xcode。不要自动下载数 GB 的 Xcode。

- [ ] **Step 2: 用 Xcode 创建最小工程**

创建 macOS App，Product Name `FinderQuickNav`，Organization Identifier `local.finderquicknav`，SwiftUI + Swift；增加 Finder Sync Extension target `FinderQuickNavExtension`。Deployment Target 设为 macOS 14.0，Swift Language Version 设为 Swift 6。

- [ ] **Step 3: 只注册用户主目录并提供背景菜单**

在 spike 的 `FinderSync.swift` 中写入：

```swift
import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [
            FileManager.default.homeDirectoryForCurrentUser
        ]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer else { return nil }
        let menu = NSMenu(title: "FinderQuickNav")
        let item = NSMenuItem(title: "快速导航", action: #selector(showQuickNav), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    @objc private func showQuickNav() {
        guard let target = FIFinderSyncController.default().targetedURL() else { return }
        NSLog("FQN target=%@ mouse=%@", target.path, NSStringFromPoint(NSEvent.mouseLocation))
    }
}
```

- [ ] **Step 4: 启用扩展并做真实 Finder 验收**

通过宿主应用调用：

```swift
FIFinderSyncController.showExtensionManagementInterface()
```

在 `~/Documents` 下 Finder 空白处右键。Expected: 只在背景菜单中出现“快速导航”；右键文件本身时不出现该入口；日志包含准确当前目录与鼠标屏幕坐标。

- [ ] **Step 5: 验证扩展唤起宿主自定义 URL**

注册 URL scheme `finderquicknav`，扩展调用：

```swift
let url = URL(string: "finderquicknav://show?ts=\(Date().timeIntervalSince1970)")!
FIFinderSyncController.default().open(url) { opened in
    NSLog("FQN host open=%@", opened.description)
}
```

Expected: 宿主收到 URL 且不激活普通主窗口。如果返回 `false` 或连续 3 次失败，在 `feasibility-results.md` 记录失败，并优先验证 `DistributedNotificationCenter + Codable` 的单向事件桥接；只有需要共享持久数据时再引入 App Group。

- [ ] **Step 6: 验证非激活面板和 Finder 当前窗口控制**

创建 `.nonactivatingPanel`，确认面板出现后 `NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"`。分别验证：

```text
返回：向 Finder 发送 Command-[
上一级：向 Finder 发送 Command-Up
跳转：让 front Finder window 的 target 变为测试目录
```

Expected: 三个动作都作用于原窗口；系统拒绝权限时能拿到明确错误。把实际结果、所需权限、失败方式写入 `feasibility-results.md`。

- [ ] **Step 7: 可行性闸门**

只有以下 5 项全部通过才进入 Task 2：背景菜单、`targetedURL`、光标坐标、宿主面板、当前窗口导航。任何一项失败都先修 spike 或更新设计，不创建完整业务模块。

---

### Task 2: 正式工程骨架与安全请求协议

**Files:**
- Create: `FinderQuickNav/Shared/QuickNavAction.swift`
- Create: `FinderQuickNav/Shared/URLRequestCodec.swift`
- Create: `FinderQuickNav/Tests/URLRequestCodecTests.swift`
- Modify: `FinderQuickNav/App/Info.plist`

**Interfaces:**
- Consumes: Task 1 选定的桥接方式。
- Produces: `QuickNavRequest` 和 `URLRequestCodec.decode(_:)`，供扩展与宿主共同使用。

- [ ] **Step 1: 写请求解析失败测试**

```swift
import XCTest
@testable import FinderQuickNav

final class URLRequestCodecTests: XCTestCase {
    func testRejectsUnknownAction() {
        let url = URL(string: "finderquicknav://run?action=erase&path=%2Ftmp&ts=1")!
        XCTAssertThrowsError(try URLRequestCodec.decode(url, now: Date(timeIntervalSince1970: 2)))
    }

    func testRejectsExpiredRequest() {
        let url = URL(string: "finderquicknav://run?action=show&path=%2Ftmp&ts=1")!
        XCTAssertThrowsError(try URLRequestCodec.decode(url, now: Date(timeIntervalSince1970: 10)))
    }
}
```

- [ ] **Step 2: 运行并确认失败**

Run:

```bash
xcodebuild test -scheme FinderQuickNav -destination 'platform=macOS' -only-testing:FinderQuickNavTests/URLRequestCodecTests
```

Expected: FAIL，因为类型尚未定义。

- [ ] **Step 3: 实现最小请求模型**

```swift
enum QuickNavAction: String, Codable {
    case show
    case createFolder
    case createText
    case createMarkdown
    case createWord
    case createExcel
    case createPowerPoint
}

struct QuickNavRequest: Equatable {
    let action: QuickNavAction
    let directoryURL: URL
    let mouseLocation: CGPoint?
    let timestamp: Date
}
```

`decode` 只接受 `finderquicknav` scheme、白名单 action、`fileURL` 目录和 5 秒内时间戳；拒绝空 path、远程 URL 和未知参数组合。宿主执行前还必须确认 Finder 是前台应用，且请求目录等于当前 Finder 窗口目标目录。

- [ ] **Step 4: 补充成功、Unicode 路径和坐标测试并运行**

Expected: 所有 `URLRequestCodecTests` PASS。

---

### Task 3: Finder 背景菜单与宿主请求桥接

**Files:**
- Create: `FinderQuickNav/Extension/FinderSync.swift`
- Create: `FinderQuickNav/Extension/ExtensionRequestBridge.swift`
- Create: `FinderQuickNav/Shared/QuickNavAction.swift`
- Modify: `FinderQuickNav/Extension/Info.plist`

**Interfaces:**
- Consumes: `QuickNavAction`、`URLRequestCodec`。
- Produces: Finder 背景菜单动作请求；宿主可收到 `QuickNavRequest`。

- [ ] **Step 1: 实现菜单结构**

```swift
override func menu(for kind: FIMenuKind) -> NSMenu? {
    guard kind == .contextualMenuForContainer else { return nil }
    let menu = NSMenu()
    menu.addItem(makeItem("快速导航", action: #selector(showQuickNav)))

    let newItem = NSMenuItem(title: "新建文件", action: nil, keyEquivalent: "")
    let submenu = NSMenu()
    submenu.addItem(makeItem("文件夹", action: #selector(createFolder)))
    submenu.addItem(makeItem("TXT", action: #selector(createText)))
    submenu.addItem(makeItem("Markdown", action: #selector(createMarkdown)))
    submenu.addItem(makeItem("Word", action: #selector(createWord)))
    submenu.addItem(makeItem("Excel", action: #selector(createExcel)))
    submenu.addItem(makeItem("PowerPoint", action: #selector(createPowerPoint)))
    newItem.submenu = submenu
    menu.addItem(newItem)
    return menu
}
```

- [ ] **Step 2: 所有动作统一走桥接**

`ExtensionRequestBridge.send(action:directoryURL:mouseLocation:)` 必须在发出请求前检查 `targetedURL()` 非空和目录存在；扩展不直接持久化收藏或显示面板。

- [ ] **Step 3: 真实 Finder 验证**

在空白处右键至少 10 次，分别点击导航和 6 个新建类型。Expected: 宿主每次只收到一个正确请求；文件项右键不出现自定义入口；没有重复菜单。

---

### Task 4: 低遮挡面板定位引擎

**Files:**
- Create: `FinderQuickNav/App/Panel/PanelPlacementEngine.swift`
- Create: `FinderQuickNav/Tests/PanelPlacementEngineTests.swift`

**Interfaces:**
- Produces: `PanelPlacementEngine.place(request:) -> CGPoint`。
- Input: 鼠标点、卡片大小、屏幕可见区域、可选 Finder 窗口区域。

- [ ] **Step 1: 写四象限和屏幕边缘测试**

```swift
func testRightEdgeChoosesLeftSide() {
    let request = PlacementRequest(
        mouse: CGPoint(x: 970, y: 500),
        panelSize: CGSize(width: 292, height: 286),
        screen: CGRect(x: 0, y: 0, width: 1000, height: 800),
        finderWindow: CGRect(x: 100, y: 100, width: 850, height: 600)
    )
    let origin = PanelPlacementEngine.place(request)
    XCTAssertLessThan(origin.x, request.mouse.x)
    XCTAssertTrue(request.screen.contains(CGRect(origin: origin, size: request.panelSize)))
}
```

再添加左边缘、顶部、Dock 区域、无 Finder window、双屏负坐标测试。

- [ ] **Step 2: 运行并确认失败**

Run:

```bash
xcodebuild test -scheme FinderQuickNav -destination 'platform=macOS' -only-testing:FinderQuickNavTests/PanelPlacementEngineTests
```

- [ ] **Step 3: 实现评分函数**

```swift
struct PlacementRequest {
    let mouse: CGPoint
    let panelSize: CGSize
    let screen: CGRect
    let finderWindow: CGRect?
}

enum PanelPlacementEngine {
    static func place(_ request: PlacementRequest) -> CGPoint {
        let gap: CGFloat = 12
        let candidates = candidateOrigins(mouse: request.mouse, size: request.panelSize, gap: gap)
        return candidates
            .map { clamp($0, size: request.panelSize, inside: request.screen) }
            .min { score($0, request) < score($1, request) }!
    }
}
```

`score` 先惩罚屏幕溢出，再惩罚与 Finder 窗口重叠面积，最后惩罚鼠标距离。四象限优先级只作为完全同分时的稳定排序。

- [ ] **Step 4: 运行测试**

Expected: 所有定位测试 PASS，返回矩形始终位于当前屏幕 `visibleFrame`。

---

### Task 5: 非激活卡片与生命周期

**Files:**
- Create: `FinderQuickNav/App/Panel/QuickNavPanelController.swift`
- Create: `FinderQuickNav/App/Panel/QuickNavView.swift`
- Modify: `FinderQuickNav/App/AppDelegate.swift`
- Modify: `FinderQuickNav/App/Info.plist`

**Interfaces:**
- Consumes: `QuickNavRequest`、`PanelPlacementEngine`。
- Produces: `show(request:)` 和 `dismiss()`。

- [ ] **Step 1: 配置后台宿主**

在 `Info.plist` 设置 `LSUIElement = YES`，宿主启动不显示 Dock 图标和普通主窗口。

- [ ] **Step 2: 创建非激活面板**

```swift
let panel = NSPanel(
    contentRect: CGRect(origin: .zero, size: CGSize(width: 292, height: 286)),
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .floating
panel.isOpaque = false
panel.backgroundColor = .clear
panel.hidesOnDeactivate = false
panel.collectionBehavior = [.transient, .moveToActiveSpace]
panel.orderFrontRegardless()
```

- [ ] **Step 3: 实现卡片 UI**

按规格实现标题、面包屑、三个主按钮、收藏/最近分页和底部管理入口。默认只显示收藏；列表最多 5 行；不要把新建文件入口放回卡片。

- [ ] **Step 4: 生命周期验收**

监听 `NSWorkspace.didActivateApplicationNotification`：当前台应用不再是 Finder 时关闭卡片。验证外部点击、Esc、目录选择和 Finder 失焦都关闭卡片；连续触发只复用一个面板实例；Finder 始终保持前台。

---

### Task 6: Finder 导航与权限

**Files:**
- Create: `FinderQuickNav/App/Navigation/FinderNavigator.swift`
- Create: `FinderQuickNav/App/Navigation/FinderWindowReader.swift`
- Create: `FinderQuickNav/App/Permissions/PermissionCenter.swift`
- Create: `FinderQuickNav/Tests/FinderNavigatorTests.swift`
- Create: `FinderQuickNav/docs/permissions.md`

**Interfaces:**
- Produces: `goBack()`, `goUp(from:)`, `navigate(to:)`, `frontFinderWindowFrame()`。

- [ ] **Step 1: 定义协议并写 mock 测试**

```swift
protocol FinderNavigating {
    func goBack() throws
    func goUp(from current: URL) throws
    func navigate(to directory: URL) throws
}

enum FinderNavigationError: Error, Equatable {
    case finderNotFrontmost
    case noFinderWindow
    case accessibilityDenied
    case automationDenied
    case invalidDirectory
}
```

测试必须覆盖 Finder 非前台时绝不发送键盘事件、根目录禁用上一级、无效路径不执行 Apple Event。

- [ ] **Step 2: 实现权限中心**

使用 `AXIsProcessTrustedWithOptions` 查询/请求辅助功能；Finder 自动化通过第一次导航捕获 `-1743` 并映射为 `automationDenied`。权限 UI 必须显示系统设置中的准确位置。

- [ ] **Step 3: 实现当前窗口动作**

返回和上一级只在 Finder 是前台时发送原生快捷键；收藏和面包屑跳转通过 Finder Apple Event 设置 front Finder window target。任何失败都返回结构化错误，不降级为静默新开窗口。

- [ ] **Step 4: 实机测试**

在一个 Finder 窗口中完成 20 次混合操作。Expected: 窗口数量不增加，路径正确，拒绝权限时应用不崩溃且提示准确。

---

### Task 7: 收藏、最近访问和卡片数据流

**Files:**
- Create: `FinderQuickNav/App/Models/FolderEntry.swift`
- Create: `FinderQuickNav/App/Storage/FavoritesStore.swift`
- Create: `FinderQuickNav/App/Storage/RecentsStore.swift`
- Create: `FinderQuickNav/Tests/FavoritesStoreTests.swift`
- Create: `FinderQuickNav/Tests/RecentsStoreTests.swift`
- Modify: `FinderQuickNav/App/Panel/QuickNavView.swift`

**Interfaces:**
- Produces: `FavoritesStore.add/remove/move/rename`；`RecentsStore.record`。

- [ ] **Step 1: 写存储规则测试**

测试 URL 标准化去重、收藏顺序、重命名只改显示名称、失效路径保留、最近访问移动到首位、最近访问最多 20 项。

- [ ] **Step 2: 实现 Codable 模型与可注入 UserDefaults**

```swift
struct FolderEntry: Codable, Identifiable, Equatable {
    let id: UUID
    var displayName: String
    let url: URL
    var lastVisitedAt: Date?
}
```

Store 初始化器接受 `UserDefaults`，测试使用独立 suite，不能污染真实偏好。

- [ ] **Step 3: 接入卡片**

打开卡片时记录当前目录；收藏当前按钮即时更新；点击条目成功导航后关闭卡片；失败路径显示“位置不可用”。

- [ ] **Step 4: 运行测试**

Expected: 存储和 UI 状态测试全部通过。

---

### Task 8: 新建文件服务与模板

**Files:**
- Create: `FinderQuickNav/App/NewFile/NewFileService.swift`
- Create: `FinderQuickNav/App/NewFile/Templates/blank.docx`
- Create: `FinderQuickNav/App/NewFile/Templates/blank.xlsx`
- Create: `FinderQuickNav/App/NewFile/Templates/blank.pptx`
- Create: `FinderQuickNav/Tests/NewFileServiceTests.swift`

**Interfaces:**
- Produces: `create(kind:in:) throws -> URL`。

- [ ] **Step 1: 写临时目录测试**

```swift
func testMarkdownCollisionDoesNotOverwrite() throws {
    let directory = try makeTemporaryDirectory()
    FileManager.default.createFile(atPath: directory.appendingPathComponent("未命名.md").path, contents: Data("old".utf8))
    let created = try service.create(kind: .markdown, in: directory)
    XCTAssertEqual(created.lastPathComponent, "未命名 2.md")
    XCTAssertEqual(try String(contentsOf: directory.appendingPathComponent("未命名.md")), "old")
}
```

添加六种类型、只读目录、模板缺失和 Unicode 路径测试。

- [ ] **Step 2: 实现冲突安全命名**

从原名开始检查，存在时依次生成 `未命名 2`、`未命名 3`；永不覆盖已有对象。

- [ ] **Step 3: 生成并验证 OOXML 空白模板**

模板必须打包进应用资源。验证：

```bash
unzip -t FinderQuickNav/App/NewFile/Templates/blank.docx
unzip -t FinderQuickNav/App/NewFile/Templates/blank.xlsx
unzip -t FinderQuickNav/App/NewFile/Templates/blank.pptx
```

Expected: 三个包均无 ZIP 错误，并能由本机 ONLYOFFICE 打开。原型或测试脚本不得在运行时依赖 ONLYOFFICE。

- [ ] **Step 4: 接入 Finder 菜单动作**

创建成功后关闭任何面板并让 Finder 显示/选中新对象；失败时显示目标目录与简短错误，不留下半成品。

---

### Task 9: 集成、性能与交付验收

**Files:**
- Create: `FinderQuickNav/docs/verification.md`
- Modify: `docs/任务进程.md`
- Modify: `docs/进度报告.md`
- Modify: `docs/决策日志.md`

**Interfaces:**
- Consumes: 所有前置任务。
- Produces: 可复现的构建、测试和真实 Finder 验收证据。

- [ ] **Step 1: 完整测试与构建**

```bash
xcodebuild test -scheme FinderQuickNav -destination 'platform=macOS'
xcodebuild -scheme FinderQuickNav -configuration Release build
```

Expected: 退出码 0，无失败测试。

- [ ] **Step 2: 真实场景矩阵**

至少验证：Finder 左上/右上/左下/右下空白处；图标视图/列表视图；浅色/深色；双屏；无权限/有权限；空目录/密集目录；路径含中文和空格；根目录；失效收藏；只读目录。

- [ ] **Step 3: 性能观察**

卡片关闭、Finder 空闲 5 分钟后，宿主和扩展应基本空闲，不持续轮询，不出现明显 CPU 占用。记录 Activity Monitor 或 `ps` 证据。

- [ ] **Step 4: 安全与发布前检查**

检查自定义 URL 白名单、时间戳、路径验证、权限错误、模板完整性。只有用户明确要求后才进行 Developer ID 签名、公证和 DMG；公证前启用 Hardened Runtime。

- [ ] **Step 5: 更新跨模型记录**

每完成一项就在 `docs/任务进程.md` 写入结果、文件、验证证据和下一条指令。不要记录隐藏思考，不要重做已经有证据的任务。

---

## Execution Handoff

DeepSeek 接手后的第一条指令不是写业务代码，而是读取：

1. `docs/任务进程.md`
2. `CONTEXT.md`
3. `docs/superpowers/specs/2026-08-06-finder-quick-nav-design.md`
4. 本实施计划

随后直接执行 Task 1 Step 1：运行 `xcodebuild -version`。如果完整 Xcode 仍未安装，只报告这个单一前置条件并等待用户安装；不要重新讨论 A/B/C，也不要先生成不可构建的 Xcode 工程。
