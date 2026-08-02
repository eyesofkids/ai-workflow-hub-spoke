#!/bin/bash
# UserPromptSubmit hook: read the API usage of the last assistant message in
# the session transcript (jsonl) — input + cache_read + cache_creation =
# actual current context token count — compute context usage, and inject a
# one-line warning once past the threshold, nudging the model toward a /wrap
# handoff at the next work-item boundary.
# The usage is measured by the API, not estimated.
#
# Known limitation: fires only when the user submits a message — during a
# single long turn (many tool calls, sub-agent dispatches) there is no
# re-poke; growth shows up on the next submission after the turn ends (and
# usage always lags by one turn).

# ── Tunables (overridable via same-named env vars) ───────
: "${THRESHOLD_PCT:=75}"          # warning threshold (%)
: "${CONTEXT_TOKENS:=1000000}"    # context window (current Sonnet/Opus/Fable are all 1M;
                                  # override to 200000 when running a 200k model, e.g. Haiku)
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
  jq -n --arg msg "⚠️ Context at ${pct}% (measured API usage ${last_usage} tokens / window ${CONTEXT_TOKENS}); consider running /wrap for a handoff at the next work-item boundary." \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$msg}}'
fi

exit 0
