#!/bin/bash
# Foundation-level regression checks. Does not install the app or restart Finder.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/zrightclick-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT
cd "$REPO"

run_test() {
    local name="$1"
    shift
    echo "==> $name"
    xcrun swiftc "$@" -o "$TEST_DIR/$name"
    "$TEST_DIR/$name"
}

run_test terminal-requests \
    ZRightClickApp/TerminalRequest.swift tests/TerminalRequestTests.swift
run_test terminal-preferences \
    Shared/Localization.swift ZRightClickApp/TerminalPreference.swift tests/TerminalPreferenceTests.swift
run_test new-files \
    Shared/Localization.swift Shared/MenuConfiguration.swift \
    ZRightClickApp/NewFileRequest.swift ZRightClickApp/NewFileWriter.swift tests/NewFileTests.swift
run_test localization \
    Shared/Localization.swift Shared/MenuConfiguration.swift \
    ZRightClickApp/TerminalPreference.swift ZRightClickApp/NewFileWriter.swift tests/LocalizationTests.swift

echo "==> Office templates"
python3 tests/validate_templates.py
echo "All checks passed."
