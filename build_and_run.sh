#!/bin/bash
# WebIsland build_and_run.sh — 플랫폼 디스패처 (macos 단일)
# 서브커맨드: build {macos} / test {macos} {smoke|unit} / e2e {macos} {smoke}
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PLATFORM="${2:-macos}"
SUITE="${3:-smoke}"

usage() {
  echo "사용법: ./build_and_run.sh {build|test|e2e} {macos} [smoke|unit]"
  echo "예시: ./build_and_run.sh build macos"
}

cmd="${1:-build}"
case "$cmd" in
  build)
    "$ROOT/scripts/env-expiry-check.sh"
    xcodebuild -project "$ROOT/WebIsland.xcodeproj" -scheme WebIsland -configuration Debug build
    ;;
  test)
    "$ROOT/scripts/env-expiry-check.sh"
    if [ "$SUITE" = "unit" ]; then
      xcodebuild test -project "$ROOT/WebIsland.xcodeproj" -scheme WebIsland -destination 'platform=macOS' 2>&1 | tail -n 20
    else
      # smoke: 빌드 통과를 최소 게이트로 사용 (테스트 타깃 추가 전까지)
      xcodebuild -project "$ROOT/WebIsland.xcodeproj" -scheme WebIsland -configuration Debug build 2>&1 | tail -n 10
    fi
    ;;
  e2e)
    echo "[안내] E2E는 사용자 승인 후 별도 수행합니다. (headless 우선, 병렬 ≤2)"
    exit 2
    ;;
  *)
    usage
    exit 1
    ;;
esac
