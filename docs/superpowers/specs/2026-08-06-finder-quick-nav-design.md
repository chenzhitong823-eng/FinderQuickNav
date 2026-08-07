# Finder 快速导航低遮挡卡片设计规格

- 日期：2026-08-06
- 状态：已确认方向，可进入可行性验证和正式实施
- 工作名称：FinderQuickNav
- 用户界面名称：快速导航

## 1. 产品目标

让用户在 Finder 文件夹空白区域右键后，用最少的鼠标移动打开一个贴近操作点、但尽量不遮挡文件的导航卡片，并在当前 Finder 窗口完成常用目录切换。

成功标准：用户无需打开额外 Finder 窗口，即可完成返回、上一级、路径层级跳转、收藏跳转、最近访问跳转和收藏当前目录；新建常用文件也能从同一空白处右键菜单进入。

## 2. 已确认交互

### 2.1 Finder 空白处右键菜单

扩展只在 Finder 文件夹背景的快捷菜单中增加两个顶级入口：

1. `⚡ 快速导航`
2. `📄 新建文件 ›`

“新建文件”子菜单包含：文件夹、TXT、Markdown、Word、Excel、PowerPoint。它与快速导航卡片分离，避免卡片过高。

### 2.2 快速导航卡片

卡片目标尺寸为 `292 × 286 pt`，允许因系统字体和辅助功能字号在 `280–340 pt` 宽、`250–360 pt` 高范围内自适应。

从上到下包含：

- 当前文件夹图标和名称。
- 一行可点击的路径面包屑，过长时中间截断，当前目录保持可见。
- 三个主操作：`返回“上一个目录名”`、`上一级`、`收藏当前`。
- 两个分页：`快速收藏`、`最近访问`。
- 当前分页最多显示 5 项，超出后卡片内部滚动。
- 底部状态：选择后自动收起；右侧进入收藏管理。

执行任一导航、点击卡片外、按 Esc 或 Finder 不再是前台应用时，卡片关闭。

### 2.3 低遮挡定位

卡片触发时读取鼠标屏幕坐标、当前屏幕可见区域和前台 Finder 窗口边界，生成四个候选位置：右、左、下、上，候选位置与鼠标保持 10–14 pt 间距。

候选评分从高到低遵循：

1. 卡片必须完整位于当前屏幕可见区域，不覆盖菜单栏或 Dock。
2. 能完全落在 Finder 窗口外、同时仍靠近鼠标时优先。
3. 必须落在窗口内时，选择与 Finder 内容区域重叠面积最小的位置。
4. 重叠面积相同时，选择鼠标移动距离更短的位置。
5. 无法读取 Finder 窗口边界时，降级为屏幕四象限放置并限制在可见区域内。

卡片是非激活面板，不抢走 Finder 的键盘焦点。这样“返回”和“上一级”可以作用于原 Finder 窗口。

## 3. 功能语义

### 返回上一位置

目标是调用 Finder 当前窗口的原生后退行为，而不是打开应用自建的历史窗口。按钮文案尽量显示目标目录名；无法可靠取得名称时显示“返回”。

### 上一级

将当前 Finder 窗口切换到当前目标 URL 的父目录。根目录时按钮禁用。

### 路径层级

每个面包屑段都是可点击目录。点击后在当前 Finder 窗口切换，不新建窗口。

### 快速收藏

- 默认空列表，由用户收藏当前目录后产生。
- 去重规则使用标准化文件 URL。
- 支持拖动排序、重命名显示名称和删除。
- 路径不存在时保留条目并显示“位置不可用”，不自动删除。

### 最近访问

- 记录每次打开卡片时的当前目录，以及通过本工具完成的目录跳转。
- 相同 URL 移到列表最前，最多保存 20 项。
- 不承诺复制 Finder 的完整全局浏览历史。

### 新建文件

- 默认名称依次为“未命名文件夹”“未命名.txt”“未命名.md”“未命名.docx”“未命名.xlsx”“未命名.pptx”。
- 名称冲突时追加空格和序号，例如“未命名 2.md”。
- TXT 与 Markdown 创建 UTF-8 空文件。
- Word、Excel、PowerPoint 从应用内置的有效空白 OOXML 模板复制，正式应用不依赖本机安装 Office 或 ONLYOFFICE。
- 创建成功后刷新当前 Finder 目录并选中新文件；如果无法进入行内重命名，至少保证文件可见并选中。

## 4. 技术架构

### 4.1 组件

1. `FinderQuickNavExtension`
   - 使用 Finder Sync。
   - 只负责监控目录、生成背景右键菜单、取得 `targetedURL` 和鼠标位置、向宿主应用发送请求。
   - 不保存复杂状态，不直接显示大卡片。

2. `FinderQuickNavApp`
   - 菜单栏/后台宿主，`LSUIElement=YES`。
   - 接收扩展请求，显示非激活 `NSPanel`。
   - 管理收藏、最近访问、权限、新建文件和 Finder 导航。

3. `PanelPlacementEngine`
   - 纯函数模块，根据鼠标、屏幕和 Finder 窗口边界返回卡片原点。
   - 必须有单元测试，不依赖真实 Finder。

4. `FinderNavigator`
   - 封装返回、上一级和跳转到 URL。
   - 导航前确认 Finder 是前台应用；权限不足时返回结构化错误。

5. `FavoritesStore` / `RecentsStore`
   - 使用宿主应用的 `UserDefaults` 存储 Codable 数据。
   - 首版扩展菜单不需要读取这些数据，因此不强制把业务状态放入扩展进程。

6. `NewFileService`
   - 创建目录、文本文件或复制内置模板。
   - 负责合法名称、冲突编号、写入失败和只读目录错误。

### 4.2 扩展到宿主通信

首选方案：Finder Sync 菜单动作将请求编码为 `finderquicknav://show?...`，通过扩展上下文请求系统打开宿主应用。该能力必须先在当前 macOS 上做实机可行性测试，因为 Apple 明确说明每个扩展点自行决定是否支持 `NSExtensionContext.open`。

如果 Finder Sync 不支持该调用，第二方案使用 App Group 共享请求数据，并用受限的进程间通知唤醒已经运行的宿主应用。不得在未验证前同时实现两套桥接。

### 4.3 监控范围

首版设置 `FIFinderSyncController.default().directoryURLs` 为当前用户主目录，覆盖 Documents、Desktop、Downloads 和主目录内项目。外接磁盘、其他用户目录和系统目录不在首版承诺范围。

## 5. 权限与安全

- Finder 扩展：引导用户在系统扩展管理界面启用。
- 辅助功能：用于把后退/上一级动作发送给当前 Finder 窗口；拒绝后按钮显示权限说明，不静默失败。
- Finder 自动化：用于把当前 Finder 窗口目标切换到收藏或路径目录；首次调用由系统提示。
- 文件访问：新建文件遇到 macOS 文件与文件夹权限限制时，显示目标目录和系统错误。
- 所有自定义 URL 请求都必须验证 scheme、action、时间戳、URL 是否为本地文件目录，并只接受白名单动作；宿主还要确认 Finder 是前台应用，且请求目录等于当前 Finder 窗口目标目录。
- 不记录文件内容、API 密钥或完整浏览行为；最近访问仅存本地 URL。

## 6. 错误处理

- 目标不存在：行项目显示不可用；点击后不导航并给出一行错误。
- 根目录：上一级禁用。
- Finder 没有窗口：卡片不显示或提示先打开 Finder 文件夹。
- Finder 不在前台：取消动作，避免快捷键发给其他应用。
- 权限拒绝：提供“打开系统设置”按钮和精确权限名称。
- 扩展未启用：宿主应用首页显示状态并打开扩展管理界面。
- 桥接失败：记录本地诊断日志，不重复启动宿主应用形成循环。

## 7. 验收标准

1. 在主目录下任意 Finder 文件夹空白处右键，出现“快速导航”和“新建文件”。
2. 点击快速导航后，卡片与鼠标距离不超过 24 pt，且完整位于屏幕可见区域。
3. 四种典型点击位置（左上、右上、左下、右下）中，卡片都选择文件遮挡更少的方向。
4. 卡片默认不高于 286 pt；收藏和最近访问不会同时展开。
5. 返回、上一级、收藏跳转和面包屑跳转都作用于原 Finder 窗口。
6. 点击外部、Esc、选择目录或 Finder 失焦后卡片关闭。
7. 新建六种对象成功；重名时不覆盖已有文件。
8. 权限拒绝、只读目录、路径失效时都有清晰反馈且不崩溃。
9. 单元测试覆盖定位、请求解析、收藏去重、最近访问、文件命名和模板复制。
10. 空闲时宿主与扩展无持续高 CPU 占用。

## 8. 首版不包含

- 剪切、复制、移动到收藏目录。
- 全局文件搜索、标签和批处理。
- 外接磁盘全覆盖。
- Finder 完整历史复制。
- 云同步、账户系统和遥测。
- App Store 上架与付费功能。

## 9. 当前环境事实

- macOS 15.7.2，Apple Silicon。
- Swift 6.1.2 Command Line Tools 可用。
- 完整 Xcode 未安装；`xcodebuild` 当前不可用。
- Xcode 16.4 官方支持 macOS 15.3 至 macOS 26.1.x，可作为当前系统的最低正式开发版本。

## 10. 官方依据

- [Finder Sync 的菜单类型](https://developer.apple.com/documentation/findersync/fimenukind)：包含 Finder 背景右键的 `contextualMenuForContainer`。
- [Finder Sync 编程指南](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)：说明监控目录、背景菜单、扩展多进程和性能约束。
- [FIFinderSyncController](https://developer.apple.com/documentation/findersync/fifindersynccontroller)：提供 `directoryURLs` 与 `targetedURL()`。
- [NSEvent.mouseLocation](https://developer.apple.com/documentation/appkit/nsevent/mouselocation)：提供屏幕坐标中的当前鼠标位置。
- [NSExtensionContext.open](https://developer.apple.com/documentation/foundation/nsextensioncontext/open(_:completionhandler:))：扩展可请求系统打开 URL，但支持条件由扩展点决定，因此列为首个实机验证项。
- [Xcode 系统要求](https://developer.apple.com/xcode/system-requirements)：Xcode 16.4 与当前 macOS 版本兼容。
