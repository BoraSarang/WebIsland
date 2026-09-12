#!/bin/bash
# env-expiry-check.sh — .env 만료 체크 (30일 전 WARN, 만료 시 빌드 실패)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -f "$ROOT/.env" ]; then
  echo "[env-expiry-check] .env 없음 — 통과 (시크릿 불필요 단계)"
  exit 0
fi
if grep -q "^EXPIRES_AT=" "$ROOT/.env"; then
  exp="$(grep "^EXPIRES_AT=" "$ROOT/.env" | cut -d= -f2)"
  now="$(date +%s)"
  exp_s="$(date -j -f "%Y-%m-%d" "$exp" +%s 2>/dev/null || date -d "$exp" +%s)"
  days=$(( (exp_s - now) / 86400 ))
  if [ "$days" -lt 0 ]; then
    echo "[env-expiry-check] ERROR: .env 만료됨 ($exp)" >&2
    exit 1
  elif [ "$days" -le 30 ]; then
    echo "[env-expiry-check] WARN: .env 만료 $days일 전 ($exp)"
  else
    echo "[env-expiry-check] OK (만료까지 ${days}일)"
  fi
else
  echo "[env-expiry-check] EXPIRES_AT 없음 — 통과"
fi
