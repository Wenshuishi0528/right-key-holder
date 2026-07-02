# 右键长按助手 Windows 版 / Right Key Holder for Windows

## 中文

这是 `右键长按助手` 的 Windows 版本。双击 `A-Start-RightKeyHolder(按这个启动).cmd` 打开工具窗口。

使用方式：

1. 打开 B 站、YouTube 或其他视频页面。
2. 先点击视频窗口，让视频页面成为当前操作对象。
3. 再点击本工具里的 `按住 ->`。
4. 需要恢复时点击 `松开 ->`。
5. 需要播放或暂停时点击 `开始/暂停`。

说明：

- Windows 版使用系统自带 PowerShell 和 Windows `SendInput` 模拟右方向键，不需要安装 Python、Node 或其他运行环境。
- 这个版本没有 macOS 的“辅助功能权限”步骤。
- 如果目标浏览器或播放器是“以管理员身份运行”，本工具也需要用管理员身份运行，否则 Windows 可能会拦截模拟按键。
- 如果按键没有作用，先点击一次工具里的 `点按 -> 测试`，确认视频窗口是否已经被正确聚焦。

## English

This is the Windows version of `Right Key Holder`. Double-click `A-Start-RightKeyHolder(按这个启动).cmd` to open the tool window.

Usage:

1. Open Bilibili, YouTube, or another video page.
2. Click the video window first so it becomes the active target.
3. Click `Hold ->` in this tool.
4. Click `Release ->` to stop.
5. Click `Play/Pause` to play or pause.

Notes:

- The Windows version uses built-in PowerShell and Windows `SendInput`; no Python, Node, or extra runtime is required.
- Windows does not need the macOS Accessibility permission step.
- If the target browser or player is running as administrator, run this tool as administrator too; otherwise Windows may block simulated input.
- If input does not work, click `Tap -> Test` first to confirm the video window is focused correctly.
