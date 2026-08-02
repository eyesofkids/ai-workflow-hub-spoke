#!/bin/bash
# UserPromptSubmit hook: roughly estimate context usage from the session
# transcript (jsonl) size, and inject a one-line warning once past the
# threshold, nudging the model toward a /wrap handoff at the next
# work-item boundary.
# The estimate is rough (transcript size ≈ an approximation of context);
# treat it as a tripwire, not a precision gauge — the JSONL envelope
# inflates the estimate = earlier warning, conservative in the right direction.

# ── Tunables ─────────────────────────────────────────────
THRESHOLD_PCT=75        # warning threshold (%), set conservatively
CONTEXT_TOKENS=200000   # estimated context window (tokens)
BYTES_PER_TOKEN=4       # rough estimate: ~4 bytes per token
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
  jq -n --arg msg "⚠️ Context estimated at ${pct}% (rough estimate from transcript size); consider running /wrap for a handoff at the next work-item boundary." \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
fi

exit 0
