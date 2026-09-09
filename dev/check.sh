#!/usr/bin/env bash
# Full local check: logic tests, QML lint, and a headless run that fails on
# any QML Error/warning the offscreen engine reports.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

QML6="${QML6:-/usr/bin/qml6}"
QMLLINT6="${QMLLINT6:-/usr/lib/qt6/bin/qmllint}"
OMARCHY_SHELL="${OMARCHY_PATH:-/usr/share/omarchy}/shell"
fail=0

echo "== logic tests =="
node dev/tests/run.mjs || fail=1

echo
echo "== qmllint (Qt6) =="
lint_out=$("$QMLLINT6" -I "$OMARCHY_SHELL" -I . Game.qml ui/*.qml 2>&1 \
  | grep -E "^(Error|Warning)" \
  | grep -vE "qs\.(Commons|Ui)|Unqualified access|Failed to import|Warnings occurred|inheritance cycle|is used but it is not resolved|unknown grouped property scope anchors|was not found\. Did you|QProcess::ExitStatus" )
if [ -n "$lint_out" ]; then echo "$lint_out"; fail=1; else echo "clean"; fi

echo
echo "== headless run (dev/shoot.qml) =="
run_out=$(QT_QPA_PLATFORM=offscreen timeout 40 "$QML6" dev/shoot.qml 2>&1)
echo "$run_out" | grep -E "saved /tmp/km-" || true
errs=$(echo "$run_out" | grep -E "Error:|is not a function|Unable to determine|TypeError|ReferenceError|Cannot read")
if [ -n "$errs" ]; then echo "QML runtime errors:"; echo "$errs"; fail=1; else echo "no runtime errors"; fi

echo
[ "$fail" -eq 0 ] && echo "ALL GREEN" || echo "FAILURES ABOVE"
exit $fail
