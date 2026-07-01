#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="右键长按助手"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$ROOT_DIR/$APP_NAME.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/RightKeyHolder"
ICON_FILE="$ROOT_DIR/assets/AppIcon.icns"
ENTITLEMENTS_FILE="$ROOT_DIR/entitlements.plist"

rm -rf "$BUILD_DIR" "$APP_DIR"
mkdir -p "$BUILD_DIR" "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swiftc \
  -O \
  -framework AppKit \
  -framework ApplicationServices \
  "$ROOT_DIR/Sources/RightKeyHolder/main.swift" \
  -o "$EXECUTABLE"

if [[ -f "$ICON_FILE" ]]; then
  cp "$ICON_FILE" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>RightKeyHolder</string>
    <key>CFBundleIdentifier</key>
    <string>local.codex.right-key-holder</string>
    <key>CFBundleName</key>
    <string>右键长按助手</string>
    <key>CFBundleDisplayName</key>
    <string>右键长按助手</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.5</string>
    <key>CFBundleVersion</key>
    <string>5</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>用于切换当前浏览器标签页里的视频播放或暂停。Used to toggle play or pause for the current browser tab video.</string>
    <key>NSAccessibilityUsageDescription</key>
    <string>用于模拟按住右方向键，方便在支持该快捷键的软件里临时倍速播放。Used to simulate holding the right arrow key for apps that support that shortcut.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Created locally for personal use.</string>
</dict>
</plist>
PLIST

app_sign_identity="${DEVELOPER_ID_APPLICATION:-}"
if [[ -z "$app_sign_identity" ]] && command -v security >/dev/null 2>&1; then
  identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  app_sign_identity="$(
    printf '%s\n' "$identities" \
      | awk -F'"' '/Developer ID Application:/ { print $2; exit }'
  )"
fi

if command -v codesign >/dev/null 2>&1; then
  if [[ -n "$app_sign_identity" ]]; then
    codesign \
      --force \
      --deep \
      --options runtime \
      --entitlements "$ENTITLEMENTS_FILE" \
      --sign "$app_sign_identity" \
      "$APP_DIR" >/dev/null
  else
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
  fi
fi

touch "$APP_DIR"
echo "$APP_DIR"
