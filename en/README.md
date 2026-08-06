# ai-workflow-hub-spoke

[中文版](../README.md)

A set of **AI collaboration workflow conventions** for Claude Code, organizing the full "plan → implement → accept" development cycle in a **hub-spoke** structure. This project contains no application code — it consists of reusable process documents and Claude Code skills, and serves as a template for adopting this working model in other projects.

![workflow](./ai-workflow_v1_en.jpg)

## Core Idea

> A plan document is a lossy projection of the decision-making process; whoever holds the live context can do that work most cheaply.

The workflow is therefore organized as: **planning and adjudication stay in the hub (a long-lived conversation with full context), execution is delegated to ticket-driven spokes (independent sessions), and quality judgments are settled by numbers (benchmarks)**.

## Roles

| Role | Responsibilities | Authority |
| --- | --- | --- |
| **User** | Go/no-go, goals, status changes (start / block / terminate) | Discretion requires **no justification** — one sentence takes effect |
| **Hub** (long-lived session with context) | Focus discussions, write plans, issue work tickets, merge spoke reports | **Versions are only produced by the hub** |
| **Spoke** (ticket-driven session) | Implementation, measurement (benchmarks), hole-finding (optional) | No versioning rights, no status fields, no adjudication rights |

## Workflow Overview

```
0. Decision discussion (hub + user) → decision document
1. Planning (hub, per mandatory checklist) → plan document → user approves directly
   (Optional: /find-holes dispatches "hole-finder spokes")
2. Implementation (spoke) → test/lint/tsc/build all green → report + runbook (wrap up with /wrap)
3. Hotfixes (same session kept alive) → append issue_log per fix
4. Acceptance (user): manual testing per runbook + diff review → commit/PR
```

## Contents

### [AGENTS.md](AGENTS.md) — The workflow conventions

Defines the full set of working rules, highlights include:

- **Document discipline**: six document types, each with a single responsibility — `decision` records the why, `plan` records the how, `facts` records verified facts (append-only), `report` records delivery status (never revised after creation), `runbook` records manual test steps, `issue_log` records the fix ledger (append-only).
- **Three provenance rules (anti-smuggling)**: "per user's ruling" must cite its source; acceptance thresholds must show their derivation; precedents are cited as "the yardstick, not the corpse."
- **Quality wager clause**: choices of model / prompt / invocation mechanism are settled exclusively by benchmarks — thresholds fixed up front, no retroactive appeals.
- **Implementation session discipline**: start by listing todos, never use compact (when context runs low, wrap up or hand off instead), deviations from the plan go into the report.
- **Mandatory plan checklist**: verify-on-cite, failure modes and time windows, gate ordering for billable calls, protection for new endpoints, implementability verification, bidirectional lifecycles — all six required, no blanks allowed.

### `.claude/skills/` — Claude Code skills

| Skill | Purpose |
| --- | --- |
| [/find-holes](.claude/skills/find-holes/SKILL.md) | Dispatches "hole-finder spokes" against a plan document: the hub trims a need-to-know work ticket, dispatches 1–3 read-only sub-agents with distinct lenses (feasibility / failure modes & concurrency / cost gates & security) to find holes, then collects their observations for the user to adjudicate. Spokes produce opinions only, never verdicts. There is also an **outsourced mode**: the hub emits a self-contained ticket as copyable text, the user pastes it into the `dispatch-broker` chat in the [vscode/](../vscode/) edition to get a heterogeneous perspective from a non-Anthropic model, then pastes the result back for synthesis. |
| [/wrap](.claude/skills/wrap/SKILL.md) | Implementation wrap-up: self-check that test/lint/tsc/build are all green, confirm report/runbook/issue_log are complete, produce a manual-test checklist and a diff-versus-plan summary for the user. When context runs low before the work is done, switch to "mid-work handoff" mode — write a handoff document, close the session, and cold-start a new one. |

### `.claude/agents/` — Sub-agent definitions

The four spokes `/find-holes` dispatches. All use **read-only tools** (Read/Grep/Glob) and share one ticket discipline: read only the files the ticket allows, never browse `_docs/`, premises are not under review; output is restricted to a list of "observation + basis" — no verdicts, no severity grades, no alternative designs, never touching "whether to do it"; every report ends with "adoption is decided by the hub and the user." Only the lens and the model differ:

| Agent | Lens | Model |
| --- | --- | --- |
| [hole-finder-feasibility.md](.claude/agents/hole-finder-feasibility.md) | Is it technically doable, what dependencies it needs, whether the existing mechanism really covers it (verify-on-cite) | sonnet |
| [hole-finder-safety.md](.claude/agents/hole-finder-safety.md) | Concurrency races, failure modes, input validation, data leaks — holes that demand deep reasoning | opus |
| [hole-finder-cost.md](.claude/agents/hole-finder-cost.md) | Whether the quota check precedes the billable call, pre-checks, cost once the limit is exceeded | sonnet |
| [hole-finder.md](.claude/agents/hole-finder.md) | Generic fallback for plans none of the three lenses fits; the hub specifies the lens in the prompt | sonnet |

The models are defaults, not locks — in the dispatch plan the hub may propose overriding them via the `model` parameter on the Agent call (e.g. pulling feasibility up to opus), with the user making the call.

### `.claude/agents/explore-haiku.md` — Cheap exploration sub-agent

[explore-haiku.md](.claude/agents/explore-haiku.md): **unrelated to the hole-finding workflow** — it is never part of `/find-holes` dispatch. It is a cheap substitute for the built-in `general-purpose` agent, doing the same broad file-reading reconnaissance (the "context firewall" in AGENTS.md) but with the model pinned to haiku and tools limited to the read-only three. Name it explicitly when dispatching, instead of letting `general-purpose` run on the inherited model.

### `.claude/hooks/` — Context-usage tripwire

[context-guard.sh](.claude/hooks/context-guard.sh) (wired up as a **UserPromptSubmit** hook in [.claude/settings.json](.claude/settings.json)): every time you submit a message, it reads the API usage (actual token count) of the last assistant message in the session transcript (jsonl) to compute context usage, and once past the threshold (default 75%) it automatically injects a one-line warning — "⚠️ context estimated at N%, consider running /wrap for a handoff at the next work-item boundary." The session gets poked by this line on every turn; combined with the discipline in AGENTS.md, the model proactively proposes a handoff at a break point — flipping "human watches the gauge" into "machine pokes the model."

The usage is a **measured API value** (input + cache_read + cache_creation from the last assistant message's usage), not an estimate. The context window defaults to **1M** (all current mainline Sonnet / Opus / Fable models are 1M); for sessions running a 200k model (e.g. Haiku as the primary model), override with the `CONTEXT_TOKENS=200000` environment variable. The threshold is likewise adjustable at the top of the script or overridable via the same-named environment variable.

**Known limitation**: the hook fires only when the user submits a message — during a single long turn (heavy implementation, sub-agent dispatches) there is no re-poke; a context spike within a turn only shows up on the next submission after the turn ends (and usage always lags by one turn).

> **Note**: placing a script in `.claude/hooks/` does NOT activate it by itself — the directory name has no special meaning; what activates the hook is the registration in `.claude/settings.json`, so when copying to a target project **bring both files** (a settings.json created mid-session is not loaded — open `/hooks` once or restart). Dependencies: **bash + jq** — works out of the box on macOS (recent versions bundle jq) and Linux (install jq yourself); **Windows requires Git Bash and jq**.

## How to Use

1. Copy (or reference) `AGENTS.md` and the whole `.claude/` directory (skills, agents, hooks, settings.json) into the target project.
2. Run `/config` in Claude Code and set **auto-compact to `off`** — this workflow never uses compact; when context runs low, wrap up or hand off via `/wrap` instead.
3. Discuss with the user in a hub session and produce decision / plan documents.
4. Once the plan is approved, open an implementation spoke session starting with "implement per document X."
5. Wrap up with `/wrap`; the user manually tests per the runbook before any commit/PR.

## Design Principles

- **Versions are only produced by the hub**: spoke output never becomes a document version directly — it is always merged through the hub.
- **Never use compact**: context compaction is lossy; when context runs low, wrap up at a natural break point or write a handoff document and cold-start. Set auto-compact to `off` as well, so it never triggers automatically.
- **Adjudication belongs to the user**: documents may not define their own overturn conditions; status-field changes are exclusively the user's.
