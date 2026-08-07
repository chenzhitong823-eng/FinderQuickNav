# Finder 快速导航项目上下文

## 项目目标

制作一个 macOS Finder 效率工具：用户在文件夹空白处右键后，可以直接进入低遮挡的快速导航卡片，完成返回上一位置、上一级、路径层级跳转、快速收藏、最近访问和收藏当前位置；右键菜单同时保留独立的“新建文件”入口。

## 已确认的产品方向

- 选定方案 C，不再比较 A/B/C。
- 卡片从右键菜单的“快速导航”项目触发，并出现在本次右键位置附近。
- 卡片必须紧凑，自动比较光标四周候选位置，优先选择遮挡文件最少的位置。
- 卡片固定包含：当前目录与路径层级、返回、上一级、收藏当前位置、快速收藏、最近访问。
- 快速收藏与最近访问使用分页切换，一次只显示一组。
- 新建文件不塞进导航卡片，继续作为 Finder 空白处右键菜单的独立入口。
- 执行导航或点击外部、按 Esc、Finder 失去焦点时，卡片自动收起。
- 卡片默认允许连续操作：上一位置、上层文件夹、收藏/最近目录和路径段跳转后保持卡片并刷新当前目录；设置页可关闭该行为。
- 当前会话会记住用户所在的分页：从“收藏”进入目录仍停留在“收藏”，从“最近访问”进入目录仍停留在“最近访问”；只有重新打开卡片时才读取默认分页设置。
- 卡片标题可拖动；路径默认只显示当前目录，悬停显示完整绝对路径；收藏/最近访问整行可点并提供蓝底白字反馈。
- 主应用名称为“man导”，提供自有应用图标；从启动台或重新打开应用时直接显示平铺式设置窗口，模块固定为快速导航、个人收藏、新建文件、权限与扩展；发送到暂不开放。

## 当前项目状态

- 已存在三个浏览器原型，C 方案已更新为低遮挡紧凑版本。
- 已有可构建的 Swift/Xcode 正式工程，宿主应用和 Finder Sync Extension 均已部署验收。
- 当前机器为 macOS 15.7.2、Apple Silicon、Swift 6.1.2。
- 已安装并选中 Xcode 16.4（Build 16F6），许可证与首次启动检查通过。

## 技术基线

- Finder 空白处菜单：Finder Sync Extension 的 `contextualMenuForContainer`。
- 当前目录：`FIFinderSyncController.default().targetedURL()`。
- 光标位置：`NSEvent.mouseLocation`，为屏幕坐标。
- 卡片：宿主应用中的 AppKit 非激活 `NSPanel`，内容用 SwiftUI。
- 扩展到宿主通信：采用 `DistributedNotificationCenter + Codable JSON`；自定义 URL 已连续 3 次实测失败并停止使用。消息包含 action、UUID、时间戳、目录 URL 和鼠标坐标，宿主会校验有效期、路径和去重。
- 宿主与扩展的持久菜单配置：使用 App Group `group.local.finderquicknav`；扩展从 `NewFilePreferencesStore` 读取新建文件启用状态和顺序。
- 当前 Finder 窗口操作：目录跳转使用 Finder Apple Event，返回/上一级使用辅助功能事件；动作前显式激活 Finder 并确认前台，权限拒绝时不发送快捷键。
- 新建文件：独立右键子菜单由扩展发送 action，宿主使用 `O_EXCL` 创建文件/文件夹，并复制打包的空白 OOXML 模板；成功后用 Finder Apple Event 显示并选中新对象。
- 首版监控范围：用户主目录及子目录；外接磁盘和任意自定义根目录后续增加。
- 首版发行方式：本机开发签名/直接分发验证，不以 App Store 上架为首要目标。
- 本机 App Group 构建：普通 Xcode 直签需要 provisioning profile；当前使用 `FinderQuickNav/scripts/build-local.sh` 先无签名 fresh build，再用本地开发证书重签，并通过 `scripts/install-local.sh` 部署。
- 应用身份：可见名称由 `CFBundleDisplayName=man导` 提供；图标源文件在 `FinderQuickNav/App/Assets.xcassets/AppIcon.appiconset/`，由工程编译为 `AppIcon.icns` 和高分辨率 `Assets.car`。当前主图标由 `FinderQuickNav/work/icon-cleanup/man-dao-rounded-transparent-1024.png` 生成，四角及图形外侧为真实透明区域，不保留截图的白边或棋盘格。
- 后台常驻：宿主使用 `LSUIElement=true`，不占 Dock、不在程序切换器出现，仍可从启动台打开设置窗口；Finder 空白处右键“快速导航/新建文件”时，扩展先把请求写入 App Group，再在宿主未运行时用 `NSWorkspace.openApplication`（`activates=false`）自动拉起宿主，宿主启动时消费待处理请求只弹卡片、不弹设置窗口。
- 路径复制：悬停路径行时行内直接显示完整路径并展开路径层级按钮（不再使用在非激活面板中无法点击的气泡）；点击路径文字或路径行任意位置即把当前文件夹完整路径复制到剪贴板，并显示“已复制”反馈。
- 点击外部关闭策略：只有点击其他应用时才收起卡片；点击本应用自己的窗口（面板、路径层级、设置窗口）不收起。
- 偏好设置入口：菜单栏房子图标（`MenuBarController`，含“打开设置”和“退出”菜单）+ 卡片右上角齿轮按钮（已验证）+ 启动台/面板“管理收藏…”。注意本机 iBar 会默认隐藏第三方菜单栏图标，需在 iBar 中把“man导”图标设为显示。

## 范围边界

首版不做剪切板增强、文件移动、云同步、全局搜索、标签管理、批量操作和 App Store 发布。最近访问只保证记录工具打开时看到的当前目录，以及通过工具完成的导航，不承诺等同于 Finder 的完整历史。

## 输出位置

- 原型：`work/prototypes/`
- 规格和执行计划：`docs/superpowers/`
- 跨模型进度：`docs/任务进程.md`
- 交互验收：`FinderQuickNav/docs/interaction-verification.md`
- 用户可见交接：`outputs/2026-08-06_Finder快速导航_DeepSeek交接.md`

## 下一模型接续规则

DeepSeek 进入项目后先读 `docs/任务进程.md` 和 `FinderQuickNav/docs/interaction-verification.md`，接受其中已有验证证据，不重做方案比较、原型、协议、导航、存储或设置实现，直接执行当前执行指令中剩余的真实 Finder 交互复测。
