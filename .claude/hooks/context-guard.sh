#!/bin/bash
# UserPromptSubmit hook：從 session transcript（jsonl）讀取最後一則 assistant 訊息的
# API usage（input＋cache_read＋cache_creation ＝ 當前 context 實際 token 數），
# 計算 context 用量，超過閾值就注入一行警告，催促模型在下個工作項邊界走 /wrap 交接。
# 用量是 API 實測值不是估算。
#
# 已知限制：只在使用者送出訊息時觸發——單一長回合（大量工具呼叫、派 sub-agent）
# 進行中不會再戳，回合結束後的下一次送訊息才會反映（usage 亦落後一個回合）。

# ── 可調參數（可用同名環境變數覆寫）─────────────────────
: "${THRESHOLD_PCT:=75}"          # 警告閾值（%）
: "${CONTEXT_TOKENS:=1000000}"    # context window（現行 Sonnet/Opus/Fable 皆 1M；
                                  # 跑 200k 模型（如 Haiku 主模型）時覆寫為 200000）
# ─────────────────────────────────────────────────────────

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

last_usage=$(jq -rs '[ .[] | select(.isSidechain != true) | .message.usage | select(.input_tokens != null)
  | (.input_tokens + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)) ]
  | last // 0' "$transcript" 2>/dev/null)

if ! [ "$last_usage" -gt 0 ] 2>/dev/null; then
  exit 0
fi

pct=$((last_usage * 100 / CONTEXT_TOKENS))

if [ "$pct" -ge "$THRESHOLD_PCT" ]; then
  jq -n --arg msg "⚠️ context 已達 ${pct}%（API usage 實測 ${last_usage} tokens／window ${CONTEXT_TOKENS}），建議在下個工作項邊界執行 /wrap 交接。" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
fi

exit 0
