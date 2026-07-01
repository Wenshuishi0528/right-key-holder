#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="右键长按助手"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
PKGROOT="$ROOT_DIR/build/pkgroot"
BUILD_SCRIPT="$ROOT_DIR/build.sh"
PKG_IDENTIFIER="local.codex.right-key-holder.pkg"

"$BUILD_SCRIPT" >/dev/null
export COPYFILE_DISABLE=1
xattr -cr "$APP_DIR" 2>/dev/null || true

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_DIR/Contents/Info.plist")"
UNSIGNED_PKG="$DIST_DIR/RightKeyHolder-$VERSION-unsigned.pkg"
SIGNED_PKG="$DIST_DIR/RightKeyHolder-$VERSION.pkg"

rm -rf "$DIST_DIR" "$PKGROOT"
mkdir -p "$DIST_DIR" "$PKGROOT"
ditto --norsrc --noextattr --noacl "$APP_DIR" "$PKGROOT/$APP_NAME.app"

pkgbuild \
  --root "$PKGROOT" \
  --install-location "/Applications" \
  --identifier "$PKG_IDENTIFIER" \
  --version "$VERSION" \
  "$UNSIGNED_PKG" >/dev/null

sign_identity="${DEVELOPER_ID_INSTALLER:-}"
if [[ -z "$sign_identity" ]] && command -v security >/dev/null 2>&1; then
  identities="$(security find-identity -v -p basic 2>/dev/null || true)"
  sign_identity="$(
    printf '%s\n' "$identities" \
      | awk -F'"' '/Developer ID Installer:/ { print $2; exit }'
  )"
fi

output_pkg="$UNSIGNED_PKG"
if [[ -n "$sign_identity" ]]; then
  productsign --sign "$sign_identity" "$UNSIGNED_PKG" "$SIGNED_PKG" >/dev/null
  rm -f "$UNSIGNED_PKG"
  output_pkg="$SIGNED_PKG"
else
  echo "No Developer ID Installer identity found; created an unsigned package for local testing." >&2
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  if [[ "$output_pkg" == "$UNSIGNED_PKG" ]]; then
    echo "NOTARY_PROFILE requires a signed package. Set DEVELOPER_ID_INSTALLER first." >&2
    exit 1
  fi

  if ! codesign -dv "$APP_DIR" 2>&1 | grep -q "Authority=Developer ID Application:"; then
    echo "NOTARY_PROFILE requires the app to be signed with Developer ID Application. Set DEVELOPER_ID_APPLICATION first." >&2
    exit 1
  fi

  xcrun notarytool submit "$output_pkg" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait >/dev/null
  xcrun stapler staple "$output_pkg" >/dev/null
fi

echo "$output_pkg"
