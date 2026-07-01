# 右键长按助手 / Right Key Holder

<img src="assets/cover.svg" width="96" alt="Right Key Holder icon">

一个 macOS 小工具：点一下开始模拟按住右方向键，再点一下松开。面板里也有 `开始/暂停` 按钮。

默认使用“按住右方向键”，用系统级模拟按键控制支持该快捷键的软件。

界面支持 `中文 / English` 切换，选择后会自动记住，下次打开继续使用上次选择的语言。

已在 B 站和 YouTube 场景测试，可用于视频快进。

当前未发布版本：`v0.5`。软件面板底部会提示：请先点击视频窗口，再点击本工具按钮。

## 使用

1. 双击下载的 `.pkg` 安装包，按提示安装。
2. 默认会安装到当前用户的桌面；需要放到其他位置时，可在安装器里更改安装位置。
3. 从安装位置打开 `右键长按助手`。
4. 第一次使用按键功能时，点面板里的“辅助功能权限”，在系统设置里允许 `右键长按助手`。
5. 打开 B 站或其他视频页面，点一下视频画面让它成为当前操作对象。
6. 点浮动面板里的“按住 →”。
7. 需要恢复时点“松开 →”。
8. 需要播放或暂停时点“开始/暂停”。

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

安装包默认使用当前用户 Home 域和 `/Desktop` 作为安装位置，所以默认会落到用户自己的桌面。需要换一个默认位置时，可运行 `DEFAULT_INSTALL_LOCATION="/Applications" ./package.sh`。

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

Right Key Holder is a small macOS utility. Click once to simulate holding the right arrow key, then click again to release it. The panel also includes a `Play/Pause` button.

The default action is `Hold Right Arrow`, which simulates holding the right arrow key for apps or websites that support that shortcut.

The UI supports `中文 / English`; your selection is saved for the next launch.

Tested with Bilibili and YouTube for video fast-forward behavior.

Current pre-release version: `v0.5`. The app panel reminds users: click the video window first, then click this tool.

### Usage

1. Double-click the downloaded `.pkg` installer and follow the prompts.
2. By default, the app installs to the current user's Desktop; use the installer's location step to choose another location.
3. Open `右键长按助手` from the install location.
4. Grant Accessibility permission when needed for right-arrow holding.
5. Focus the video page or player.
6. Click `Hold →`.
7. Click `Release →` to stop.
8. Click `Play/Pause` to play or pause.
