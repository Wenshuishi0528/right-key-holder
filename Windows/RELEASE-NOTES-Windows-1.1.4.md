# Right Key Holder Windows v1.1.4

## 中文

这是 `右键长按助手` 的 Windows 修复版。macOS 版本本次不变，Windows 版已替换旧包。

下载 Windows 版后，解压并双击：

```text
A-Start-RightKeyHolder(按这个启动).cmd
```

Release 资产：

- macOS：`RightKeyHolder-1.1-unsigned.pkg`（本次不变）
- Windows：`RightKeyHolder-Windows-1.1.4.zip`（替换旧 Windows 包）

### 修复内容

- 修复点击 `Hold` 后无法再点击 `Release` 结束快进的问题。
- 修复部分 Windows 机器上 `Hold` 点击后仍显示 `Not holding`、没有进入按住状态的问题。
- 将 `Hold / Release` 从普通 `Click` 事件改为鼠标按下时立即执行，避免 WinForms 在持续模拟右方向键时丢失按钮点击。
- 增强目标视频窗口捕获：工具窗口失去焦点时会快速记录当前前台窗口，不只依赖定时器轮询。
- 下载并内置 GitHub 仓库封面图，窗口顶部和窗口图标都使用同一张封面。
- 保留 `Esc` 作为备用释放方式：工具窗口获得焦点时按 `Esc` 可强制结束按住。

### 问题原因和解决思路

旧 Windows 版在进入 Hold 后会持续发送右方向键。用户再点回工具窗口准备 Release 时，Windows 的焦点切换、WinForms 的按钮 `Click` 事件、以及持续模拟按键会互相影响，导致 Release 按钮有时看起来能点但没有执行停止逻辑。后续尝试中如果过度依赖 `SetForegroundWindow` 的即时结果，又会在某些 Windows 环境里导致 Hold 根本启动不了。

最终修复思路是把状态切换从 `Click` 事件提前到 `MouseDown`：鼠标按下按钮时立即开始或停止，不再等待可能被焦点变化影响的 Click。启动时只要已有目标窗口就先进入 Holding 状态，再尝试聚焦并发送右方向键；停止时先停掉定时器、切回空闲状态，再发送右方向键松开信号。目标窗口记录也从单纯 250ms 定时轮询，增强为工具窗口失焦后快速捕获前台窗口。

## English

This is the Windows fix release for `Right Key Holder`. The macOS version is unchanged in this release; the old Windows package has been replaced.

After downloading the Windows package, unzip it and double-click:

```text
A-Start-RightKeyHolder(按这个启动).cmd
```

Release assets:

- macOS: `RightKeyHolder-1.1-unsigned.pkg` (unchanged)
- Windows: `RightKeyHolder-Windows-1.1.4.zip` (replaces the old Windows package)

### Fixes

- Fixed the issue where `Release` could fail after clicking `Hold`.
- Fixed the issue where some Windows machines stayed at `Not holding` after clicking `Hold`.
- Moved `Hold / Release` handling from the normal `Click` event to mouse-down so the action runs before focus changes can swallow the click.
- Improved target video-window capture when the tool loses focus, instead of relying only on periodic polling.
- Added the GitHub cover image to the Windows app window and icon.
- Kept `Esc` as a backup force-release key while the tool window is focused.

### Root Cause And Approach

The old Windows version continuously sent right-arrow input while Hold was active. When the user clicked back into the tool window to release, Windows focus changes, WinForms button click handling, and the repeated simulated key input could interfere with each other. That made the Release button appear clickable without reliably running the stop logic. A stricter focus check also caused Hold to fail on systems where Windows delayed or denied immediate foreground-window switching.

The final fix moves the state transition to mouse-down, so starting and stopping no longer depend on the later Click event. Hold now enters the holding state once a target window exists, then attempts focus and sends the right-arrow key down. Release stops the timer first, returns the UI to idle, and then sends right-arrow key-up. Target-window tracking was also improved by capturing the foreground window shortly after the tool loses focus.
