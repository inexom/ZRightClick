#!/bin/bash
# Lay out a drag-to-install image without Apple Events or Finder scripting.
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${1:?Usage: package-dmg.sh /absolute/ZRightClick.app version output.dmg}"
VERSION="${2:?Missing version}"
OUTPUT="${3:?Missing output path}"
TOOLS="$REPO/build/dmg-tools"
[[ -d "$APP" && "$APP" == /* && "$OUTPUT" == /* ]] || { echo "Use absolute app/output paths" >&2; exit 2; }
if ! "$TOOLS/bin/python" -c 'import ds_store, mac_alias' 2>/dev/null; then
    python3 -m venv "$TOOLS"
    "$TOOLS/bin/python" -m pip install -r "$REPO/scripts/dmg-requirements.txt"
fi
WORK="$(mktemp -d "$REPO/build/dmg-staging.XXXXXX")"
MOUNT="$WORK/volume"
MOUNTED=false
cleanup() {
    if $MOUNTED; then
        if ! /usr/bin/hdiutil detach "$MOUNT"; then
            echo "Could not detach $MOUNT; preserving $WORK" >&2
            return
        fi
    fi
    rm -rf "$WORK"
}
trap cleanup EXIT
mkdir -p "$WORK/files/.background" "$MOUNT"
/usr/bin/ditto "$APP" "$WORK/files/ZRightClick.app"
ln -s /Applications "$WORK/files/Applications"
xcrun swift "$REPO/scripts/dmg-background.swift" "$WORK/files/.background/background.png"
/usr/bin/hdiutil create -volname "ZRightClick $VERSION Installer" -srcfolder "$WORK/files" \
    -fs HFS+ -format UDRW "$WORK/writable.dmg"
/usr/bin/hdiutil attach -nobrowse -noautoopen -mountpoint "$MOUNT" "$WORK/writable.dmg"
MOUNTED=true
"$TOOLS/bin/python" "$REPO/scripts/dmg-layout.py" "$MOUNT"
/usr/bin/hdiutil detach "$MOUNT"
MOUNTED=false
/usr/bin/hdiutil convert "$WORK/writable.dmg" -format UDZO -ov -o "$OUTPUT"
/usr/bin/hdiutil verify "$OUTPUT"
