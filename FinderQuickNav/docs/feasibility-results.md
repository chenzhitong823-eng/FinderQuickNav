# FinderQuickNav 可行性验证结果

- 日期：2026-08-06
- 测试系统：macOS 15.7.2，Apple Silicon
- 工具链：Xcode 16.4（16F6）、Swift 6.1.2、XcodeGen 2.46.0
- 规范测试应用：`/Users/mac/Applications/FinderQuickNav.app`

## 五项闸门

| 项目 | 状态 | 实机证据 |
|---|---|---|
| Finder 空白处背景菜单 | 通过 | `/Users/mac/Documents` 空白处右键可见“快速导航” |
| 当前目录 `targetedURL()` | 通过 | 日志记录 `/Users/mac/Documents` |
| 鼠标屏幕坐标 | 通过 | 日志记录坐标，例如 `{585, 317}` |
| 宿主非激活卡片 | 通过 | 卡片显示前后前台应用均为 `com.apple.finder`；实测尺寸 `292 × 286` |
| 当前 Finder 窗口导航 | 通过 | 上一级、返回、Codex 目录跳转均成功；窗口数量不变，最后恢复到“文稿” |

## 扩展到宿主通信

### 自定义 URL：失败并停止

- 扩展能正确生成 `finderquicknav://show` 请求。
- `FIFinderSyncController.open` 连续 3 次返回 `false`。
- 宿主没有收到 URL Apple Event。
- 结论：不再使用或重试自定义 URL。

### 分布式通知：通过

- 参考 RClick 的公开架构，独立实现 `DistributedNotificationCenter + Codable JSON` 的单向点击事件。
- 不使用 RClick 源码，不引入 GPL 文件，不使用心跳轮询。
- 连续 3 次 Finder 点击均完成 Extension → Main 传输。
- 每次发送与接收日志的 UUID、目录、鼠标坐标、时间戳一致。

## 关键实现约束

- Finder Sync Extension 必须启用 App Sandbox 才能稳定注册。
- 沙盒内的 `NSHomeDirectory()`、Foundation home 和环境变量 `HOME` 都指向扩展容器。
- 监听真实用户主目录必须使用 `getpwuid(getuid())`；本机结果为 `/Users/mac`。
- 宿主必须处于运行状态才能接收分布式通知；正式版后续补登录启动/生命周期策略。
- 正式请求协议已校验时间戳、路径、鼠标数值并去重；新建文件请求还按 action 映射到受限类型。

## 新建文件实机结果

- 独立菜单：Finder 空白处显示“新建文件”，子菜单包含文件夹、TXT、Markdown、Word、Excel、PowerPoint。
- TXT：真实点击创建 `/Users/mac/Documents/FinderQuickNav-Integration-Test/未命名.txt`，大小 0 字节。
- Word：真实点击创建并选中 `/Users/mac/Documents/FinderQuickNav-Integration-Test/未命名.docx`，大小 1287 字节；`unzip -t` 无错误。
- 测试目录和文件已整体移入 `FinderQuickNav/system/archive/FinderQuickNav-integration-artifacts/`，未留在用户文稿目录。
- 当前部署：`/Users/mac/Applications/FinderQuickNav.app`；`pluginkit` 只登记一个启用扩展。

## 下一条执行指令

进入 Task 9：执行 Release 构建、全量回归、真实场景矩阵、性能观察，并生成 `FinderQuickNav/docs/verification.md`。
