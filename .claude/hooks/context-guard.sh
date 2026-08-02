#!/bin/bash
# UserPromptSubmit hook：用 session transcript（jsonl）大小粗估 context 用量，
# 超過閾值就注入一行警告，催促模型在下個工作項邊界走 /wrap 交接。
# 估算是粗的（transcript 大小 ≈ context 的近似），定位是絆線不是精密儀表——
# JSONL 的 JSON 外殼會讓估值偏高＝提早警告，方向上剛好保守。

# ── 可調參數 ──────────────────────────────────────────────
THRESHOLD_PCT=75        # 警告閾值（%），保守設定
CONTEXT_TOKENS=200000   # context window 估計值（tokens）
BYTES_PER_TOKEN=4       # 粗估：每 token 約 4 bytes
# ─────────────────────────────────────────────────────────

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

if [ -z "$transcript" ] || [ ! -f "$transcript" ]; then
  exit 0
fi

size=$(wc -c < "$transcript" | tr -d ' ')
est_tokens=$((size / BYTES_PER_TOKEN))
pct=$((est_tokens * 100 / CONTEXT_TOKENS))

if [ "$pct" -ge "$THRESHOLD_PCT" ]; then
  jq -n --arg msg "⚠️ context 預估已達 ${pct}%（依 transcript 大小粗估），建議在下個工作項邊界執行 /wrap 交接。" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
fi

exit 0
