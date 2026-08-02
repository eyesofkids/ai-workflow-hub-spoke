
---

## Plan → Implement → Accept Workflow Conventions (Hub-Spoke Model)

> A plan document is a lossy projection of the decision-making process; whoever holds the live context can do that work most cheaply. This section is organized accordingly: planning and adjudication happen in the context-holding hub, execution happens in ticket-driven spokes, and quality judgments are settled by numbers.

### Roles

| Role | Responsibilities | Authority |
| --- | --- | --- |
| **User** | Go/no-go, goals, status changes (start / block / terminate) | Discretion requires **no justification** — one sentence takes effect |
| **Hub** (long-lived conversation with context) | Focus discussions, write plans, issue work tickets, merge spoke reports, analyze divergence against the original intent | **Versions come only from the hub** |
| **Spoke** (ticket-driven session) | Implementation (= review + implementation), measurement (benchmarks), hole-finding (optional) | No versioning rights, no status fields, no adjudication rights |

### Workflow Overview

```
0. Decision discussion (hub + user) → decision document
1. Planning (hub, per the mandatory checklist) → plan document → user approves directly
   (Optional: the user names a hole-finder spoke — sub-agent, need-to-know ticket,
    produces opinions not verdicts; skill: /find-holes)
2. Implementation (spoke, opening with "implement per document X") → completion condition =
   `pnpm run test`/`lint`/`tsc`/`build` all green → report + runbook (wrap-up skill: /wrap)
3. Hotfixes (same session kept alive until the fix wave ends) → append issue_log per fix;
   do not go back to sync report/runbook
4. Acceptance (user): behavioral acceptance (manual test per runbook) + diff review
   (faithful to the plan, no smuggling) + business judgment → commit/PR
```

### Document Discipline

- Six document types, each with a single responsibility: **decision** records the why / **plan** records the how / **facts** (append-only) records verified facts / **report** records delivery status (never revised after creation) / **runbook** records manual test steps / **issue_log** records the fix ledger (append-only; messiness is normal).
- New versions record only the delta; background is a one-line reference to the decision document, never restated.
- Status-field changes belong exclusively to the user; **documents may not define their own overturn conditions** ("this document can only be overturned by X" is a red flag).

### Three Provenance Rules (Anti-Smuggling)

1. "Per the user's ruling / already settled" **must come with provenance** (the exact words, when, and what question was being answered); without provenance it is treated as unsettled. Procedural replies ("not yet", "wait a moment") must not be promoted into substantive decisions.
2. Acceptance thresholds **must come with their derivation** (a measured baseline from the same mechanism, or user-specified); numbers the model makes up are invalid. The baseline used to calibrate a threshold must come from the same mechanism — change two variables at once and the threshold is void before anything else.
3. Cite precedents as **"the yardstick, not the corpse"**: a verdict is portable only under "same problem + same cost structure"; "that case died so this one will too" is not an argument.

### Quality Wager Clause

Choices of model / prompt / invocation mechanism are settled exclusively by benchmarks: thresholds are fixed up front, with no retroactive appeals; options below threshold are not force-adopted; negative results are archived together with their result files, and later proposals of the same kind must first face the existing measurements.

### Implementation Session Discipline

- Start by listing todos (TodoWrite — an anchor that survives context compaction); delegate heavy file-reading reconnaissance to sub-agents (a context firewall).
- **Never use compact** (it is lossy, and after compaction the hot session's value is already dead): when context runs low → wrap up at the last natural break point — finished work goes through `/wrap`, **unfinished work goes through `/wrap`'s mid-work handoff mode** (write a handoff document `handoff_<topic>.md`) → close the session → a new session cold-starts from the plan document + handoff. If a conversation opens with "This session is being continued" → re-read the plan document; do not trust specs from the summary.
- Deviations from the plan during construction → record in the report (under the "mid-construction corrections" section); incidental same-file fixes (unrelated lint errors, etc.) are allowed — log them in issue_log.

### Mandatory Checklist for Writing Implementation Plans (MUST)

Every item must have an explicit answer in the plan, or be explicitly marked as "a deliberately accepted trade-off" — no blanks allowed:

1. **Verify on cite**: every claim of "an existing mechanism already covers this / zero changes needed / X filtering is already there" requires actually opening the file and tracing the **complete semantics** (including branches, unions / secondary tables, fallback paths) — never rely on file names, comments, or line numbers alone. When citing, attach the key semantics that support the conclusion, not just the location.
2. **Failure modes and time windows**: for every mechanism, write down its behavior on failure — before the scheduled job has run? after retries are exhausted? under concurrent races? "At most N times" without a following "and when exhausted, …" is an unfinished design.
3. **Gate ordering for billable calls**: for any call that incurs external API cost (LLM / STT / image generation / embedding), quota or gate checks must happen **before** the call; "deduct only after success" requires an additional read-only pre-check up front, and must answer "once the limit is exceeded, what happens on every subsequent request, and what does it cost?"
4. **Mandatory protection for new endpoints**: every new API route must explicitly state three things — auth level, rate limit, and request body size limit; "not needed" also requires a written reason. If the project already has a documented fix for the same class of vulnerability, cite that document as the standard.
5. **Implementability verification**: for every "the backend validates X / the code layer guarantees Y", answer whether the backend can technically do it and what dependencies it needs; replace what can't be done with an implementable alternative (e.g., a two-stage design: coarse pre-filter up front + precise check afterward).
6. **Bidirectional lifecycles**: any "publish/unpublish, enable/disable, expiry" mechanism must be defined in both directions (writing only the unpublish sweep without the republish backfill = a gap); check whether all index-like replicas (embeddings, variants, caches, projections) follow along on state changes.

### Independent Review

Plan documents are not sent to any independent session for review, and restoring such review must not be suggested; the "guidance for review gates" in historical `_docs` no longer applies. Clean perspectives exist exclusively in the form of "hole-finder spokes" (see step 1 of the workflow overview and the `/find-holes` skill).

---
