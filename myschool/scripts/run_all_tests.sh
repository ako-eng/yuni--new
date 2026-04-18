#!/usr/bin/env bash
# 一键：后端 pytest + iOS 工程编译。联调烟测（需已启动后端）可加 RUN_LIVE=1。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PARENT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKEND_DIR="$APP_PARENT/myschool_back"
IOS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Backend pytest ($BACKEND_DIR)"
cd "$BACKEND_DIR"
python3 -m pip install -q -r requirements-dev.txt 2>/dev/null || python3 -m pip install -q pytest
python3 -m pytest tests/ -v

echo "==> iOS build ($IOS_ROOT)"
cd "$IOS_ROOT"
xcodebuild -scheme myschool -destination 'generic/platform=iOS' -quiet build

if [[ "${RUN_LIVE:-}" == "1" ]]; then
  echo "==> Live API (RUN_LIVE=1, BASE_URL=${BASE_URL:-http://127.0.0.1:5001})"
  BASE_URL="${BASE_URL:-http://127.0.0.1:5001}" bash "$SCRIPT_DIR/verify_notice_api.sh"
fi

echo "全部完成（未设 RUN_LIVE=1 时未跑需后端的 curl 烟测）。"
