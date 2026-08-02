#!/bin/bash
# UserPromptSubmit hook: extract the actual conversation content from the
# session transcript (jsonl) — message text + tool outputs, excluding
# metadata lines and sub-agent sidechains — convert to tokens, roughly
# estimate context usage, and inject a one-line warning once past the
# threshold, nudging the model toward a /wrap handoff at the next
# work-item boundary. A tripwire, not a precision gauge.
#
# Known limitation: fires only when the user submits a message — during a
# single long turn (many tool calls, sub-agent dispatches) there is no
# re-poke; growth shows up on the next submission after the turn ends.

# ── Tunables (overridable via same-named env vars) ───────
: "${THRESHOLD_PCT:=75}"        # warning threshold (%)
: "${CONTEXT_TOKENS:=200000}"   # estimated context window (tokens)
: "${BASELINE_TOKENS:=30000}"   # fixed base: system prompt + tool definitions (tokens)
# content bytes → tokens via ×2/7 (≈3.5 bytes/token, mixed-language calibration)
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
  # jq parse failure → fall back to total-size estimate (bytes/10, rough
  # calibration that discounts metadata inflation)
  size=$(wc -c < "$transcript" | tr -d ' ')
  est_tokens=$((size / 10 + BASELINE_TOKENS))
fi

pct=$((est_tokens * 100 / CONTEXT_TOKENS))

if [ "$pct" -ge "$THRESHOLD_PCT" ]; then
  jq -n --arg msg "⚠️ Context estimated at ${pct}% (content-based rough estimate); consider running /wrap for a handoff at the next work-item boundary." \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
fi

exit 0
