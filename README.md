# 右键长按助手 / Right Key Holder

<img src="RightKeyHolder/assets/cover.svg" width="96" alt="Right Key Holder icon">

## 中文

右键长按助手是一个 macOS 小工具：点一下开始模拟按住右方向键，再点一下松开。它适合在 B 站、YouTube 或其他支持方向键快进/长按快进的视频页面和播放器里使用，也提供一个 `开始/暂停` 按钮。

默认模式是 `按住右方向键`。如果网页不识别模拟按键，也可以切到 `网页 3x`，直接把当前浏览器标签页的视频设为 3 倍速。

界面支持 `中文 / English` 切换，并会记住上次选择的语言。

已在 B 站和 YouTube 场景测试，可用于视频快进。

`开始/暂停` 会优先直接切换当前浏览器标签页里的视频播放状态；如果当前窗口不是支持的浏览器，则退回到发送一次空格键，适配本地播放器或其他网页播放器。

## English

Right Key Holder is a small macOS utility: click once to simulate holding the right arrow key, then click again to release it. It is useful for video pages and players that support right-arrow fast-forward or hold-to-fast-forward behavior, including Bilibili and YouTube. It also includes a `Play/Pause` button.

The default mode is `Hold Right Arrow`. If a web page does not recognize simulated key events, switch to `Web 3x` to set the current browser tab's video playback rate directly to 3x.

The UI supports `中文 / English` and remembers the last selected language.

Tested with Bilibili and YouTube for video fast-forward behavior.

`Play/Pause` first tries to toggle the current browser tab's video playback state directly. If the current window is not a supported browser, it falls back to sending one Space key press for local players or other web players.

## Build

```bash
./RightKeyHolder/build.sh
```

The app is generated at:

```text
RightKeyHolder/右键长按助手.app
```
