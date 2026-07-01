# 右键长按助手 / Right Key Holder

<img src="assets/cover.svg" width="96" alt="Right Key Holder icon">

一个 macOS 小工具：点一下开始模拟按住右方向键，再点一下松开。面板里也有 `开始/暂停` 按钮。Windows 版本在仓库根目录的 `Windows` 文件夹里。

制作起因：我在看 B 站时，如果想让视频临时三倍速（3x），需要一直按住键盘右方向键，时间久了很麻烦。所以我写了这个小程序，把原本需要一直按住的动作变成点一下就能完成，像一个省力的辅助工具一样方便操作。

默认使用“按住右方向键”，用系统级模拟按键控制支持该快捷键的软件。

界面支持 `中文 / English` 切换，选择后会自动记住，下次打开继续使用上次选择的语言。

已在 B 站和 YouTube 场景测试，可用于视频快进。

当前正式版本：`v1.1`。软件面板底部会提示：请先点击视频窗口，再点击本工具按钮。

## 使用

1. 双击下载的 `.pkg` 安装包，按提示安装。
2. 从“应用程序”里打开 `右键长按助手`。
3. 第一次使用按键功能时，点面板里的“辅助功能权限”，在系统设置里允许 `右键长按助手`。
4. 打开 B 站或其他视频页面，点一下视频画面让它成为当前操作对象。
5. 点浮动面板里的“按住 →”。
6. 需要恢复时点“松开 →”。
7. 需要播放或暂停时点“开始/暂停”。

## 本地开发

### 重新构建

```bash
./build.sh
```

构建完成后会生成：

```text
RightKeyHolder/build/右键长按助手.app
```

### 生成安装包

```bash
./package.sh
```

安装包会生成在：

```text
RightKeyHolder/dist/
```

没有 Apple Developer 证书时，脚本会生成未签名安装包用于本地测试。公开给普通用户下载前，需要安装 `Developer ID Application` 和 `Developer ID Installer` 证书，脚本会自动使用它们签名。设置 `NOTARY_PROFILE` 为已保存的 `notarytool` 钥匙串 profile 后，脚本会继续公证并 staple 安装包。

## 手动运行

1. 双击打开本地构建出的 `右键长按助手.app`。
2. 第一次使用按键模式时，点面板里的“辅助功能权限”，在系统设置里允许 `右键长按助手`。
3. 打开 B 站或其他视频页面，点一下视频画面让它成为当前操作对象。
4. 点浮动面板里的“按住 →”。
5. 需要恢复时点“松开 →”。
6. 需要播放或暂停时点“开始/暂停”。

## 功能

- `按住右方向键`：默认功能，给 B 站、本地播放器或其他支持右方向键长按的软件使用。第一次使用需要在系统设置里允许辅助功能权限。
- `开始/暂停`：优先直接切换当前浏览器标签页里的视频播放状态；如果当前窗口不是支持的浏览器，则退回到发送一次空格键。

## 图标

- 封面源文件：`assets/cover.svg`
- macOS app 图标：`assets/AppIcon.icns`

## 注意

- Safari 使用“开始/暂停”时，可能需要在 Safari 的开发菜单里允许“来自 Apple 事件的 JavaScript”。
- 如果当前光标在输入框里，右方向键会作用到输入框，所以使用按键模式前先点一下视频画面。
- 如果“开始/暂停”显示“请允许本工具控制浏览器”，到系统设置的“隐私与安全性 > 自动化”里允许它控制浏览器。
- 如果重新构建 app 后辅助功能权限看起来已经开启但仍然无效，退出 app，到“系统设置 > 隐私与安全性 > 辅助功能”里删除旧的 `右键长按助手`，再重新添加当前生成的 app。未上架签名的本地 app 每次重新构建后，macOS 可能会把它当成一个新的程序。

## English

Right Key Holder is a small macOS utility. Click once to simulate holding the right arrow key, then click again to release it. The panel also includes a `Play/Pause` button. The Windows version is in the repository-level `Windows` folder.

Why I built it: while watching Bilibili, I found that temporary 3x playback requires holding the keyboard's right arrow key the whole time, which gets annoying. I made this small app to turn that long press into one click, so it feels like a simple assistive helper for video control.

The default action is `Hold Right Arrow`, which simulates holding the right arrow key for apps or websites that support that shortcut.

The UI supports `中文 / English`; your selection is saved for the next launch.

Tested with Bilibili and YouTube for video fast-forward behavior.

Current release version: `v1.1`. The app panel reminds users: click the video window first, then click this tool.

### Usage

1. Double-click the downloaded `.pkg` installer and follow the prompts.
2. Open `右键长按助手` from Applications.
3. Grant Accessibility permission when needed for right-arrow holding.
4. Focus the video page or player.
5. Click `Hold →`.
6. Click `Release →` to stop.
7. Click `Play/Pause` to play or pause.
