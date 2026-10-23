#!/bin/bash
# Build and package an ad-hoc-signed universal macOS release. Does not publish.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-1.0}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || { echo "Usage: $0 [version, e.g. 1.0]" >&2; exit 2; }
OUT="$REPO/build/releases/v$VERSION"
APP="$OUT/build/ZRightClick.app"
EXT="$APP/Contents/PlugIns/ZRightClickFinderExtension.appex"
NAME="ZRightClick-$VERSION-universal"
mkdir -p "$OUT"
STAGING="$(mktemp -d "$REPO/build/release-staging.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT

echo "==> Building $VERSION for arm64 and x86_64 (ad-hoc signed, not notarized)"
xcodebuild \
  -project "$REPO/ZRightClick.xcodeproj" \
  -scheme ZRightClick \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$REPO/build/release-derived-data" \
  CONFIGURATION_BUILD_DIR="$OUT/build" \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO \
  MARKETING_VERSION="$VERSION" \
  CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY=- CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  build > "$OUT/build.log" 2>&1 || { cat "$OUT/build.log"; exit 1; }

for BUNDLE in "$APP" "$EXT"; do
  /usr/bin/codesign --verify --deep --strict "$BUNDLE"
  ARCHITECTURES="$(/usr/bin/lipo "$BUNDLE/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$BUNDLE/Contents/Info.plist")" -archs)"
  for ARCHITECTURE in arm64 x86_64; do
    case " $ARCHITECTURES " in
      *" $ARCHITECTURE "*) ;;
      *) echo "Missing $ARCHITECTURE in $BUNDLE" >&2; exit 1 ;;
    esac
  done
  ACTUAL_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$BUNDLE/Contents/Info.plist")"
  [[ "$ACTUAL_VERSION" == "$VERSION" ]] || { echo "Bundle version mismatch: $ACTUAL_VERSION" >&2; exit 1; }
done

python3 - "$APP" "$EXT" <<'PY'
import plistlib
from pathlib import Path
import subprocess
import sys

for path in sys.argv[1:]:
    bundle = Path(path)
    for architecture in ('arm64', 'x86_64'):
        payload = subprocess.check_output([
            'codesign', '-d', '--arch', architecture, '--entitlements', '-', '--xml', str(bundle)
        ], stderr=subprocess.DEVNULL)
        entitlements = plistlib.loads(payload)
        assert entitlements.get('com.apple.security.app-sandbox') is True, bundle
        assert entitlements.get('com.apple.security.files.user-selected.read-write') is True, bundle
        assert not entitlements.get('com.apple.security.get-task-allow', False), bundle
    print(f'{bundle.name}: sandbox entitlements verified for both architectures')
PY

echo "==> Packaging DMG and ZIP"
/usr/bin/ditto "$APP" "$STAGING/ZRightClick.app"
ln -s /Applications "$STAGING/Applications"
cp "$REPO/docs/INSTALL.txt" "$STAGING/安装说明 - Read Me.txt"
/usr/bin/hdiutil create -volname "ZRightClick $VERSION" -srcfolder "$STAGING" -format UDZO -ov "$OUT/$NAME.dmg"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/$NAME.zip"
(
  cd "$OUT"
  /usr/bin/shasum -a 256 "$NAME.dmg" "$NAME.zip" > SHA256SUMS.txt
)
echo "Artifacts: $OUT"
cat "$OUT/SHA256SUMS.txt"
