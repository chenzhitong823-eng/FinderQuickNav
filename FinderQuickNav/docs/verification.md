# FinderQuickNav 验证记录

- 日期：2026-08-06
- 系统：macOS 15.7.2，Apple Silicon
- Xcode：16.4（16F6）
- Swift：6.1.2
- 安装副本：`/Users/mac/Applications/FinderQuickNav.app`
- 签名：`FinderQuickNav Local Signing`

## 构建与资源

Release 构建命令：

```bash
xcodebuild -project FinderQuickNav/FinderQuickNav.xcodeproj \
  -scheme FinderQuickNav \
  -configuration Release \
  -derivedDataPath FinderQuickNav/build-release \
  clean build -quiet
```

结果：

- Release build 成功。
- 宿主和扩展 `CFBundleVersion` 均为 `1`。
- `codesign --verify --deep --strict` 通过。
- `pluginkit` 只登记一个启用扩展，路径为安装副本中的 `FinderQuickNavExtension.appex`。
- `blank.docx`、`blank.xlsx`、`blank.pptx` 均通过 `unzip -t`。

交互增量加入 App Group 后的本机验证：

```bash
zsh FinderQuickNav/scripts/build-local.sh
FQN_CONFIGURATION=Release zsh FinderQuickNav/scripts/build-local.sh
zsh FinderQuickNav/scripts/install-local.sh
```

- Debug/Release 均 fresh build 成功，并通过宿主/扩展重签和 `codesign --verify --deep --strict`。
- 当前本机没有 provisioning profile；普通带 App Group entitlement 的直签 `xcodebuild` 会在签名输入阶段失败，因此本机使用脚本的无签名构建后本地重签流程。
- App 和 Extension 都声明 `group.local.finderquicknav`；`scripts/test-app-group-config.sh` 通过。
- `scripts/verify-extension-registration.sh` 已强化为同一 bundle ID 必须只有一个注册项。

## 自动回归

以下 smoke test 均通过：

- 新建文件服务：六种类型、冲突命名、中文路径、只读目录、模板缺失。
- bridge 消息和请求 codec：action、时间戳、路径校验、UUID 去重。
- 收藏与最近访问：持久化、去重、顺序、数量上限。
- 卡片位置：屏幕边界和低遮挡候选位置。
- Finder 导航策略、Apple Event 路径转义和权限错误映射。
- 主目录解析、扩展请求 URL builder。

## 实际 Finder 验收

已覆盖：


- Finder 空白处右键显示“快速导航”。
- 独立“新建文件”子菜单显示：文件夹、TXT、Markdown、Word、Excel、PowerPoint。
- 图标视图下菜单入口正常。
- 列表视图下菜单入口正常，测试后已恢复图标视图。
- TXT 实际创建 `未命名.txt`。
- Word 实际创建并选中 `未命名.docx`；文件通过 ZIP 完整性检查。
- 快速导航卡片已在 Finder 前台、低遮挡位置显示；导航实测作用于原 Finder 窗口且不增加窗口数量。
- 旧版本和实机测试文件均移动到 `FinderQuickNav/system/archive/`，没有永久删除。

交互增量已实际看到：

- C 卡片标题、上一位置、上层文件夹、当前目录摘要、收藏/最近分页、整行目录按钮、收藏当前位置和管理收藏入口。
- 点击上层文件夹后卡片保持显示并刷新目录；点击上一位置后仍保持显示。
- 管理收藏入口可以打开平铺式设置窗口；四个设置模块可以切换。
- 新建文件设置页的 Word 开关可以关闭并恢复开启；App Group 容器 lookup 日志成功。

拖动手势、面板外点击关闭、路径 hover、整行空白鼠标命中和清理重复注册后的 Finder 菜单刷新，详见 `interaction-verification.md`，目前仍需一次干净现场复测。

## 空闲观察

卡片关闭、Finder 保持空闲时，对安装副本的宿主和扩展做了两次间隔 10 秒的 `ps` 采样：两者 CPU 均为 `0.0`，未发现持续轮询迹象。该记录是短时观察，不替代 Instruments 长时分析。

## 尚未覆盖

- 四个屏幕角、双屏和 Finder 全屏模式下的真实卡片截图矩阵；已有 placement 单元 smoke test 覆盖屏幕边缘。
- 浅色/深色模式下的视觉回归。
- 空目录、根目录、失效收藏和只读 Finder 目录的完整 UI 矩阵；服务层已有只读/模板缺失测试。
- ONLYOFFICE 实际打开三种 OOXML 文件；当前已确认 ZIP 结构完整，未在本机自动启动第三方办公软件。
- Developer ID 签名、公证、DMG 和 App Store 发布；这些不在当前授权范围内。

## 工具利用检查

- 本任务可用工具：Xcode、XcodeGen、Swift smoke test、`codesign`、`pluginkit`、`unzip`、Computer Use。
- 已使用工具：Xcode/XcodeGen 构建、Swift smoke test、资源生成脚本、签名和扩展注册检查、Finder Computer Use 实机验收。
- 未使用但可考虑工具：Instruments、ONLYOFFICE、XCTest UI 测试；前两者会扩大验证范围，后者当前工程使用独立 smoke test 以便跨模型续作。
- 是否需要安装新工具：不需要。
- 安装原因：无。
- 安装后如何验证：不适用；现有工具均已通过本次最小验证。
- 安装后如何复用：不适用。
- 是否已写入工具资产台账：本次没有安装新工具，不新增台账条目。

## 结论

当前版本适合作为本机开发签名的可运行交付版本：核心 Finder 菜单、低遮挡导航卡片、收藏/最近访问和独立新建文件均已接入并有实机证据。后续若继续推进，优先补“多屏/深色/四角真实截图矩阵”和长时 Instruments 观察，再考虑发布签名与打包。
