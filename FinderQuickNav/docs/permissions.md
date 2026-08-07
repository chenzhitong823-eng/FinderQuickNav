# FinderQuickNav 权限说明

## 当前状态

2026-08-06 初次实测宿主日志为：

```text
FQN navigation accessibilityGranted=false
```

当时返回和上一级会安全返回 `accessibilityDenied`，不会发送键盘事件。该状态已由用户授权解决。

用户随后已完成授权，最新日志为 `accessibilityGranted=true`。真实导航已通过；工具操作期间 ToDesk/Codex 可能成为前台，导航器会先激活 Finder 后再发送动作。

## 需要的权限

1. 打开“系统设置”。
2. 进入“隐私与安全性” → “辅助功能”。
3. 添加并启用 `/Users/mac/Applications/FinderQuickNav.app`。
4. 第一次点击收藏目录跳转时，如果 macOS 询问是否允许 FinderQuickNav 控制 Finder，选择允许。

## 设计约束

- Finder 不是前台应用时，导航器拒绝操作。
- 根目录不允许执行“上一级”。
- 不存在或不是目录的目标不会发送 Apple Event。
- `-1743` 映射为 `automationDenied`；无 Finder 窗口映射为 `noFinderWindow`；其他状态保留原始错误码。
- 未授权时不静默打开新 Finder 窗口，也不模拟绕过系统权限。

## 授权后的验收

- 已在一个 Finder 窗口中验证返回、上一级、Codex 项目跳转。
- 确认窗口数量不增加、Finder 仍为前台、路径发生预期变化。
- 再重复混合操作并记录系统拒绝时的提示。
