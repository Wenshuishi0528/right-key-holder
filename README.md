# 右键长按助手 / Right Key Holder

<img src="RightKeyHolder/assets/cover.svg" width="96" alt="Right Key Holder icon">

## 中文

右键长按助手是一个 macOS / Windows 小工具：点一下开始模拟按住右方向键，再点一下松开。它适合在 B 站、YouTube 或其他支持方向键快进/长按快进的视频页面和播放器里使用，也提供一个 `开始/暂停` 按钮。

制作起因：我在看 B 站时，如果想让视频临时三倍速（3x），需要一直按住键盘右方向键，时间久了很麻烦。所以我写了这个小程序，把原本需要一直按住的动作变成点一下就能完成，像一个省力的辅助工具一样方便操作。

默认功能是 `按住右方向键`，用系统级模拟按键控制支持该快捷键的软件。

界面支持 `中文 / English` 切换，并会记住上次选择的语言。

已在 B 站和 YouTube 场景测试，可用于视频快进。

`开始/暂停` 在 macOS 上会优先直接切换当前浏览器标签页里的视频播放状态；如果当前窗口不是支持的浏览器，则退回到发送一次空格键。Windows 版会切回上一个视频窗口并发送一次空格键。

当前正式版本：`v1.1`。软件面板底部会显示：

```text
请先点击视频窗口，再点击本工具按钮。
B站按住效果为视频三倍速。
YouTube按住效果为视频快进。
```

## English

Right Key Holder is a small macOS / Windows utility: click once to simulate holding the right arrow key, then click again to release it. It is useful for video pages and players that support right-arrow fast-forward or hold-to-fast-forward behavior, including Bilibili and YouTube. It also includes a `Play/Pause` button.

Why I built it: while watching Bilibili, I found that temporary 3x playback requires holding the keyboard's right arrow key the whole time, which gets annoying. I made this small app to turn that long press into one click, so it feels like a simple assistive helper for video control.

The default action is `Hold Right Arrow`, which simulates holding the right arrow key for apps or websites that support that shortcut.

The UI supports `中文 / English` and remembers the last selected language.

Tested with Bilibili and YouTube for video fast-forward behavior.

On macOS, `Play/Pause` first tries to toggle the current browser tab's video playback state directly. If the current window is not a supported browser, it falls back to sending one Space key press. On Windows, it focuses the previous video window and sends one Space key press.

Current release version: `v1.1`. The app panel shows:

```text
Click the video window first, then click this tool.
Bilibili hold: 3x video speed.
YouTube hold: video fast-forward.
```

## 安装

下载 `.pkg` 安装包，双击打开，按 macOS 安装器提示继续。软件会安装到 `/Applications`。

第一次使用右方向键长按时，macOS 仍然需要你手动允许辅助功能权限。打开软件后点击“辅助功能权限”，在系统设置里允许 `右键长按助手`，再回到软件继续使用。

Windows 版本不需要安装额外运行环境。进入 `Windows` 文件夹，双击 `A-Start-RightKeyHolder(按这个启动).cmd` 即可打开。

如果目标浏览器或播放器是“以管理员身份运行”，Windows 版也需要用管理员身份运行，否则系统可能会拦截模拟按键。

## Install

Download the `.pkg` installer, double-click it, and follow the macOS installer. The app will be installed into `/Applications`.

The first time you use right-arrow holding, macOS still requires Accessibility permission. Open the app, click the Accessibility button, enable `右键长按助手`, then return to the app.

The Windows version does not need an extra runtime. Open the `Windows` folder and double-click `A-Start-RightKeyHolder(按这个启动).cmd`.

If the target browser or player is running as administrator, run the Windows tool as administrator too; otherwise Windows may block simulated input.

## 构建 / Build

macOS:

```bash
./RightKeyHolder/build.sh
```

The app is generated at:

```text
RightKeyHolder/build/右键长按助手.app
```

Windows:

```text
Windows/A-Start-RightKeyHolder(按这个启动).cmd
```

The Windows version is a PowerShell + WinForms utility and does not require a build step.

## 打包 / Package

```bash
./RightKeyHolder/package.sh
```

The installer is generated under:

```text
RightKeyHolder/dist/
```

没有 Apple Developer 证书时，脚本会生成未签名安装包用于本地测试。公开给普通用户下载前，需要安装 `Developer ID Application` 和 `Developer ID Installer` 证书；脚本会自动使用它们签名。设置 `NOTARY_PROFILE` 为已保存的 `notarytool` 钥匙串 profile 后，脚本会继续公证并 staple 安装包。

Without Apple Developer certificates, the script creates an unsigned package for local testing. For public downloads, install `Developer ID Application` and `Developer ID Installer` certificates; the scripts will use them automatically. Set `NOTARY_PROFILE` to a saved `notarytool` keychain profile to notarize and staple the package.
