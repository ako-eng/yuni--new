#!/usr/bin/env bash
# 校园通知后端联调自检（需在 myschool_back 已启动时使用）
# 默认 5001，避免 macOS 上 5000 常被 AirPlay 占用。若需其它端口：
#   export BASE_URL=http://127.0.0.1:8080

set -euo pipefail
BASE_URL="${BASE_URL:-http://127.0.0.1:5001}"

echo "==> BASE_URL=$BASE_URL"
echo "==> GET /api/health"
code=$(curl -sS -o /tmp/myschool_health.json -w "%{http_code}" -m 10 "$BASE_URL/api/health" || echo "000")
echo "    HTTP $code"
if [[ "$code" != "200" ]]; then
  echo "    FAIL: 期望 200。若见 403 且 Server 为 AirTunes，说明访问到了 AirPlay（常见为误用 5000），请确认后端端口与 BASE_URL 一致。"
  exit 1
fi
cat /tmp/myschool_health.json
echo ""

echo "==> GET /api/notices?page=1&per_page=2"
code=$(curl -sS -o /tmp/myschool_notices.json -w "%{http_code}" -m 60 -G "$BASE_URL/api/notices" \
  --data-urlencode "page=1" --data-urlencode "per_page=2" || echo "000")
echo "    HTTP $code"
if [[ "$code" != "200" ]]; then
  echo "    FAIL"
  exit 1
fi
head -c 800 /tmp/myschool_notices.json
echo ""
echo ""

echo "==> GET /api/categories"
code=$(curl -sS -o /tmp/myschool_cat.json -w "%{http_code}" -m 10 "$BASE_URL/api/categories" || echo "000")
echo "    HTTP $code"
if [[ "$code" != "200" ]]; then
  echo "    WARN: categories 非 200（无 gdut_notices.json 时可能为 404），通知列表仍可能可用。"
else
  head -c 600 /tmp/myschool_cat.json
  echo ""
fi

echo "==> 中文 keyword（UTF-8）"
code=$(curl -sS -o /tmp/myschool_kw.json -w "%{http_code}" -m 60 -G "$BASE_URL/api/notices" \
  --data-urlencode "page=1" --data-urlencode "per_page=5" --data-urlencode "keyword=通知" || echo "000")
echo "    HTTP $code"
[[ "$code" == "200" ]] || exit 1

echo "==> POST /api/notices/add（联调烟测，会写入一条标题含 _curl_verify_ 的通知）"
code=$(curl -sS -o /tmp/myschool_add.json -w "%{http_code}" -m 30 -X POST "$BASE_URL/api/notices/add" \
  -H "Content-Type: application/json" \
  -d '{"title":"_curl_verify_","category":"综合通知","content":"curl 联调","department":"","tags":"a,b"}' || echo "000")
echo "    HTTP $code"
if [[ "$code" != "201" ]]; then
  echo "    FAIL: 期望 201（若 404 多为服务器上缺 gdut_notices.json）"
  cat /tmp/myschool_add.json 2>/dev/null || true
  exit 1
fi
grep -q '"status": "success"' /tmp/myschool_add.json && grep -q '"notice"' /tmp/myschool_add.json || { echo "FAIL: 响应缺 success/notice"; exit 1; }
head -c 400 /tmp/myschool_add.json
echo ""

echo "OK — 接口可访问。请在模拟器/真机将 myschool.api.baseURL 设为同一 BASE_URL（UserDefaults 或代码中的 APIConfiguration）。"
