#!/bin/bash
# UserPromptSubmit hook：從 session transcript（jsonl）抽出實際對話內容
# （訊息文字＋工具輸出，排除 metadata 行與 sub-agent sidechain），
# 換算 token 粗估 context 用量，超過閾值就注入一行警告，
# 催促模型在下個工作項邊界走 /wrap 交接。定位是絆線不是精密儀表。
#
# 已知限制：只在使用者送出訊息時觸發——單一長回合（大量工具呼叫、
# 派 sub-agent）進行中不會再戳，回合結束後的下一次送訊息才會反映。

# ── 可調參數（可用同名環境變數覆寫）─────────────────────
: "${THRESHOLD_PCT:=75}"        # 警告閾值（%）
: "${CONTEXT_TOKENS:=200000}"   # context window 估計值（tokens）
: "${BASELINE_TOKENS:=30000}"   # system prompt＋工具定義等固定基底（tokens）
# 內容 bytes → tokens 以 ×2/7 換算（≈3.5 bytes/token，中英混合的校準值）
# ─────────────────────────────────────────────────────────

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

content_bytes=$(jq -rs '
  [ .[]
    | select(.isSidechain != true)
    | .message.content?
    | select(. != null)
    | if type == "array" then
        map(
          .text // .thinking
          // (if .content != null then (if (.content|type)=="string" then .content else (.content|tojson) end) else null end)
          // (if .input != null then (.input|tojson) else null end)
          // ""
        ) | join("")
      else tostring end
  ] | map(utf8bytelength) | add // 0' "$transcript" 2>/dev/null)

if [ -n "$content_bytes" ] && [ "$content_bytes" -ge 0 ] 2>/dev/null; then
  est_tokens=$((content_bytes * 2 / 7 + BASELINE_TOKENS))
else
  # jq 解析失敗 → 退回總大小估算（bytes/10，扣掉 metadata 灌水的粗校準）
  size=$(wc -c < "$transcript" | tr -d ' ')
  est_tokens=$((size / 10 + BASELINE_TOKENS))
fi

pct=$((est_tokens * 100 / CONTEXT_TOKENS))

if [ "$pct" -ge "$THRESHOLD_PCT" ]; then
  jq -n --arg msg "⚠️ context 預估已達 ${pct}%（內容基準粗估），建議在下個工作項邊界執行 /wrap 交接。" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
fi

exit 0
