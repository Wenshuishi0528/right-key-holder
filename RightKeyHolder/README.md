# 右键长按助手

一个 macOS 小工具：点一下开始倍速，再点一下恢复。

默认使用“按住右方向键”模式，用系统级模拟按键控制支持该快捷键的软件。也可以切到“网页 3x”模式，直接把当前浏览器标签页里的视频设为 3 倍速。

界面支持 `中文 / English` 切换，选择后会自动记住，下次打开继续使用上次选择的语言。

## 使用

1. 双击打开 `右键长按助手.app`。
2. 第一次使用按键模式时，点面板里的“辅助功能权限”，在系统设置里允许 `右键长按助手`。
3. 打开 B 站或其他视频页面，点一下视频画面让它成为当前操作对象。
4. 点浮动面板里的“按住 →”。
5. 需要恢复时点“松开 →”。

## 模式

- `按住右方向键`：默认模式，给 B 站、本地播放器或其他支持右方向键长按的软件使用。第一次使用需要在系统设置里允许辅助功能权限。
- `网页 3x`：备用模式，适合模拟按键不被网页识别时使用。支持 Chrome、Edge、Brave、Vivaldi、Opera、Arc、Safari。

## 重新构建

```bash
./build.sh
```

构建完成后会生成：

```text
RightKeyHolder/右键长按助手.app
```

## 图标

- 封面源文件：`assets/cover.svg`
- macOS app 图标：`assets/AppIcon.icns`

## 注意

- Safari 可能需要在 Safari 的开发菜单里允许“来自 Apple 事件的 JavaScript”。
- 如果当前光标在输入框里，右方向键会作用到输入框，所以使用按键模式前先点一下视频画面。
- 如果网页模式显示“请允许本工具控制浏览器”，到系统设置的“隐私与安全性 > 自动化”里允许它控制浏览器。
- 如果重新构建 app 后辅助功能权限看起来已经开启但仍然无效，退出 app，到“系统设置 > 隐私与安全性 > 辅助功能”里删除旧的 `右键长按助手`，再重新添加当前生成的 app。未上架签名的本地 app 每次重新构建后，macOS 可能会把它当成一个新的程序。

## English

Right Key Holder is a small macOS utility. Click once to start speed-up behavior, then click again to restore.

The default mode is `Hold Right Arrow`, which simulates holding the right arrow key for apps or websites that support that shortcut. You can switch to `Web 3x` to set the current browser tab's video playback rate directly to 3x.

The UI supports `中文 / English`; your selection is saved for the next launch.

### Usage

1. Open `右键长按助手.app`.
2. For key-hold mode, grant Accessibility permission when needed.
3. Focus the video page or player.
4. Click `Hold →`.
5. Click `Release →` to stop.
