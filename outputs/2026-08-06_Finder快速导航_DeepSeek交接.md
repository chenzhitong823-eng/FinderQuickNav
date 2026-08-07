# Finder 快速导航：DeepSeek 接续入口

## 已确定结论

- 采用方案 C。
- 右键空白处选择“快速导航”后，在原操作点附近显示紧凑卡片。
- 卡片自动从右、左、下、上四个位置中选择遮挡文件最少的位置。
- 卡片约 `292 × 286 pt`；收藏和最近访问分页显示。
- 新建文件保留为独立右键入口，不放进卡片。
- 导航尽量作用于当前 Finder 窗口。
- 卡片标题支持拖动；默认导航后保持打开，文案使用“上一位置”“上层文件夹”。
- 路径默认仅显示当前目录，悬停显示完整绝对路径；收藏和最近访问整行可点。
- 收藏/最近访问分页属于当前卡片会话：从哪个分页进入目录，刷新后仍停留在哪个分页；重新打开卡片才读取默认分页。
- 已加入平铺式设置窗口：快速导航、个人收藏、新建文件、权限与扩展；发送到暂不开放。
- Finder 扩展从 App Group `group.local.finderquicknav` 读取新建文件启用状态和顺序。
- 主应用可见名称为“man导”，图标使用用户提供的企鹅少女图；截图中误截的相邻图标残片已清理。从启动台启动或重新打开时显示“man导 设置”。

## 已完成文件

- [项目上下文](../CONTEXT.md)
- [跨模型进度](../docs/任务进程.md)
- [交互验收记录](../FinderQuickNav/docs/interaction-verification.md)
- [产品与技术规格](../docs/superpowers/specs/2026-08-06-finder-quick-nav-design.md)
- [交互增量规格](../docs/superpowers/specs/2026-08-06-finder-quick-nav-interaction-design.md)
- [详细实施计划](../docs/superpowers/plans/2026-08-06-finder-quick-nav.md)
- [交互增量计划](../docs/superpowers/plans/2026-08-06-finder-quick-nav-interaction.md)
- [已选交互原型](finder-quicknav-prototypes/variant-c.html)

## DeepSeek 的第一步

1. 先读 `../docs/任务进程.md`，不要重新做方案比较。
2. 运行：

```bash
xcodebuild -version
xcrun swift --version
```

3. 再读 `../FinderQuickNav/docs/interaction-verification.md`，确认当前单一安装副本和剩余真实 UI 验收项。
4. 运行：

```bash
zsh ../FinderQuickNav/scripts/verify-extension-registration.sh
zsh ../FinderQuickNav/scripts/build-local.sh
```

5. 注意：当前机器没有 provisioning profile，带 App Group 的普通 Xcode 直签会失败；使用 `build-local.sh` 的无签名构建后本地重签流程，不要删除 entitlement。
6. 只继续复测拖动、面板外关闭、路径 hover、整行空白命中和设置后菜单刷新；不要重做 bridge、导航、存储、新建文件或设置窗口。

分页状态和“man导”启动设置窗口/图标已经完成并通过回归、资源检查和真实系统应用识别，不要重新实现；本地安装脚本已对 `pluginkit` 异步注册加入重试等待和 Launch Services 注册。

## Task 1 必须拿到的五项证据

- Finder 背景右键菜单出现。
- `targetedURL()` 返回准确当前目录。
- `NSEvent.mouseLocation` 返回触发点屏幕坐标。
- 宿主非激活卡片出现且 Finder 保持前台。
- 返回、上一级、目录跳转作用于原 Finder 窗口。

核心五项已经通过；当前只剩交互增量的真实 UI 复测和四角/双屏/深色模式等可选验收。
