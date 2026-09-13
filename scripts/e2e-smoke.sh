#!/bin/bash
# E2E smoke (TC-SMOKE-001/002) — 실행 유지형 (재시작 겸함).
# AX 권한·포커스 스틸 없이 프로세스·로그·defaults로만 확인. 예산 ≤2분.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$HOME/Applications/WebIsland.app"
BUILT="$HOME/Library/Developer/Xcode/DerivedData/WebIsland-dexfglfvykbryqbfkxnqfolheqyw/Build/Products/Debug/WebIsland.app"
BUNDLE="com.borasarang.WebIsland"
LOG="$HOME/Library/Caches/WebIsland/debug.log"
PASS=0
FAIL=0

check() { # check <이름> <조건식...>
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then echo "[PASS] $name"; PASS=$((PASS+1));
    else echo "[FAIL] $name"; FAIL=$((FAIL+1)); fi
}

# 0) 기존 실행 종료 (재시작) + 교체 복사
pkill -f "WebIsland.app/Contents/MacOS/WebIsland" 2>/dev/null || true
sleep 1
rm -rf "$APP"
cp -R "$BUILT" "$APP"

# 1) 기동
open "$APP"
for _ in $(seq 1 10); do
    pgrep -f "WebIsland.app/Contents/MacOS/WebIsland" >/dev/null && break
    sleep 1
done
check "TC-SMOKE-001a 프로세스 기동(10s)" pgrep -f "WebIsland.app/Contents/MacOS/WebIsland"

# 2) 시작 로그 (15s 폴링)
FOUND=1
for _ in $(seq 1 15); do
    grep -q "메뉴바 앱 시작" "$LOG" 2>/dev/null && { FOUND=0; break; }
    sleep 1
done
if [ "$FOUND" -eq 0 ]; then echo "[PASS] TC-SMOKE-001b 시작 로그"; PASS=$((PASS+1));
else echo "[FAIL] TC-SMOKE-001b 시작 로그"; FAIL=$((FAIL+1)); fi

# 3) 단축키 기본값 (TC-SMOKE-002)
check "TC-SMOKE-002 togglePanel(⌘⇧W)" defaults read "$BUNDLE" KeyboardShortcuts_togglePanel
check "TC-SMOKE-002 debugPanel(⌘⇧D)" defaults read "$BUNDLE" KeyboardShortcuts_debugPanel

echo "---"
echo "SMOKE: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
