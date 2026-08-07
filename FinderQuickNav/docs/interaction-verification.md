# FinderQuickNav 交互增量验收记录

日期：2026-08-07

## 代码与构建回归

- `scripts/test-settings-preferences.sh`：通过。
- `scripts/test-settings-section.sh`：通过。
- `scripts/test-app-group-config.sh`：通过。
- `scripts/test-finder-navigation-policy.sh`：通过。
- `scripts/test-path-display.sh`：通过。
- folder stores、bridge、request codec、new-file、placement、permission、window script、monitored root 和 URL builder 脚本：全部通过。
- 原型三个 `variant-*.html` 的 `<script>` 编译：通过；`work/prototypes/variant-c.html` 与输出副本一致。
- `zsh scripts/build-local.sh`：Debug fresh build、重签、深度签名通过。
- `FQN_CONFIGURATION=Release zsh scripts/build-local.sh`：Release fresh build、重签、深度签名通过。
- `scripts/test-app-identity.sh`：名称、普通 Launchpad 应用配置、启动设置窗口入口和 AppIcon 资源检查通过。
- `scripts/test-app-icon-transparency.sh`：旧图标先在不透明角和右缘截图白色样点失败；新 1024 主资源通过，全部 16–1024 AppIcon 尺寸均确认含 alpha。

## 本机签名限制

工程已经声明 App Group entitlement，但本机只有 `FinderQuickNav Local Signing` 证书，没有开发者 provisioning profile。直接运行带 App Group entitlement 的普通 `xcodebuild ... build` 会在签名输入阶段报告“requires a provisioning profile”。这不是 Swift 编译错误。

本机开发使用：

```bash
zsh scripts/build-local.sh
FQN_CONFIGURATION=Release zsh scripts/build-local.sh
zsh scripts/install-local.sh
```

脚本先无签名构建，再用现有本地证书分别重签宿主和 Finder 扩展，并验证 `group.local.finderquicknav`。正式团队签名时应改为 Apple Developer profile，不应删除 App Group entitlement。

## 已实际看到的 UI

Computer Use 曾读取到真实设置窗口，模块包括：

- 快速导航：导航后保持卡片打开、悬停时显示完整路径、默认分页；
- 个人收藏：添加目录、显示名、启用、排序、删除；
- 新建文件：文件夹、TXT、Markdown、Word、Excel、PowerPoint 的启用和排序；
- 权限与扩展：辅助功能状态和系统设置入口。

真实 C 卡片 AX 树包含拖动标题帮助、`上一位置`、`上层文件夹`、房子图标、当前目录短名、收藏/最近分页、整行目录按钮、收藏当前位置和 `管理收藏…`。

已验证：

1. 从 `课堂` 点击“上层文件夹”，卡片保持显示并刷新为 `Documents`。
2. 点击“上一位置”，卡片保持显示并刷新为 `课堂`。
3. 点击“管理收藏…”，打开设置窗口并进入个人收藏模块。
4. 新建文件设置页的 Word 开关可以写为关闭，随后已恢复开启，避免改变用户原有菜单偏好。
5. 在单一当前安装副本下，扩展初始化日志记录真实用户主目录；App Group 容器读取成功。
6. 启动 `/Users/mac/Applications/FinderQuickNav.app` 后，系统应用列表显示名称为“man导”；设置窗口使用“man导 设置”标题。
7. “最近访问”分页会话状态由 smoke test 覆盖：选择最近访问后导航，分页仍为最近访问；收藏分页同理。
8. 图标已替换为用户最新图片的真实透明圆角版本：外部白边与棋盘格背景不再进入 AppIcon，角色画面未用生成式方式改动。
9. 宿主以 `LSUIElement=true` 后台运行：不占 Dock；Finder 空白处右键点“快速导航”时自动拉起宿主，窗口列表只有 292×286 卡片、无设置窗口，App Group 待处理请求被消费。
10. 悬停路径行显示完整路径与 `/ › Users › mac › Documents` 层级按钮；点击路径文字或行任意位置后 `pbpaste` 返回当前文件夹路径，卡片内显示绿色“已复制”。
11. 点击外部关闭只对非本应用窗口生效；点击本应用自己的窗口（路径层级、设置窗口）不会误关卡片。
12. 卡片右上角齿轮按钮可打开“man导 设置”窗口（已真实点击验证）；菜单栏房子图标已创建，但被本机 iBar 收入隐藏区，需在 iBar 中设为显示。

## 尚未形成独立证据的项目

- Computer Use 的拖动坐标受到 Retina/窗口坐标转换影响，尚未稳定完成一次拖动后位置变化的证据；代码已设置 `isMovable` 和 `isMovableByWindowBackground`，标题也提供拖动帮助。
- 面板外点击关闭、路径悬停完整绝对路径、整行空白区域命中和分页动画尚未分别截取稳定的真实 UI 证据；纯模型/静态检查已通过。
- 设置修改后 Finder 右键菜单的动态刷新曾受到残留 `build-release` 扩展副本影响；该副本已经从 `pluginkit` 移除，当前注册脚本只允许一个扩展，但需要下一轮从干净 Finder 现场复测。
- 启动台图标已使用高分辨率 `Assets.car` AppIcon 资源；用户提供截图的相邻图标残片已裁掉，Launch Services 已读取 `CFBundleDisplayName=man导`。
- 已清理归档区旧版宿主进程（与正式版同 bundle ID，会干扰“宿主是否在运行”判断）。
- 系统权限现状：自动化（控制 Finder）与文稿访问已允许；完全磁盘访问待用户授权（需密码/Touch ID），已打开对应系统设置面板。

## 现场清理

- 旧安装 App 移动到 `system/archive/`，没有永久删除。
- 残留 `build-release` Finder 扩展已通过 `pluginkit -r` 移除；工作区构建目录仍保留，不作为安装注册副本。
- Finder 当前目录在测试过程中恢复为 `课堂`，Word 新建入口已恢复启用。
- 本轮安装脚本首次遇到 `pluginkit` 注册异步竞态，已加入最多 8 秒重试；再次安装成功并通过唯一扩展校验。

## 下一步

先确认：

```bash
scripts/verify-extension-registration.sh
```

输出必须只有一个 `local.finderquicknav.app.extension`，路径为 `/Users/mac/Applications/FinderQuickNav.app/Contents/PlugIns/FinderQuickNavExtension.appex`。然后在 Finder 前台、没有设置窗口覆盖时复测剩余四项 UI 交互；不要重新实现 bridge、导航、存储或设置页。
