---
name: wrap
description: Implementation wrap-up and pre-acceptance checks — self-check the four greens (test/lint/tsc/build), confirm report/runbook/issue_log are complete, produce the user's manual-test checklist and diff-versus-plan summary, and remind to switch sessions (no compact). Use when an implementation session finishes, or when context runs low.
---

# wrap — Implementation Wrap-Up

You are an implementation spoke, wrapping up. First determine the mode:

- **Finished wrap-up** (default): work items are complete → follow sections 1–4.
- **Mid-work handoff**: context is running low and the work is unfinished → go straight to section 5 ("all green before closing" does not apply).

## 1. Self-Check: Four Greens

- `pnpm exec vitest run <*.test.ts of the modules changed this round>` (**only the ones you changed** — see the testing rules in AGENTS.md for scoping; no full-suite runs, no piping into `| sort`/`| head`/`| tail`)
- `pnpm exec tsc --noEmit`
- Run `eslint` on the files changed this round
- `pnpm run build`

If any item is not green: fix it before continuing the wrap-up; never close with reds.

## 2. Document Checks

- **report**: produced? Does it include a "mid-construction corrections" section (where the implementation deviated from the plan)?
- **runbook**: produced? Does it include manual test steps for the parts machines can't test (environment, paths, operation order, expected results)?
- **issue_log**: is every fix made after this round's report recorded entry by entry? (report/runbook are never revised retroactively — see document discipline in AGENTS.md)

## 3. Produce the Acceptance Package (final message to the user)

Present in this order:

1. **Manual-test checklist**: extract from the runbook the items the user must verify by hand, listed one by one (steps + expected result) — don't make the user dig through the runbook themselves.
2. **Diff-versus-plan summary**: the list of actually changed files vs. the plan's file list, mapped one to one; **changes beyond the plan explicitly flagged** (smuggling is an acceptance red line).
3. **Open items**: problems found during implementation but not handled (logged in issue_log for later, or needing the user's ruling).

## 4. Closing Reminders

- **Do not suggest committing** — per the Git safety rules in AGENTS.md, present the diff to the user for confirmation first.
- **No compact**: if context is already tight, say explicitly: "this session should close; follow-up fixes can continue in this session (hotfixes); if this session has gone cold or been truncated, open a new session and cold-start from report + issue_log."
- During a fix wave: append issue_log per fix.

## 5. Mid-Work Handoff (context low, work unfinished)

**No compact** — after compaction the map has been lossily compressed and the hot session's value is already dead; write a handoff document instead, then close the session.

1. Update todo states (done / in progress / untouched).
2. Write the handoff document `_docs/<domain>/handoff_<topic>.md` (same topic shares one file — append), containing:
   - The plan document path + which work item you are on
   - The list of half-changed files + each one's state (e.g., "X.ts changed but untested", "Y.ts half done, missing Z")
   - The current red/green state (which tests are green, which are red, and why)
   - The next step (concrete down to "open which file and do what")
   - Environment notes and traps (dev server port, flaky tests, workarounds)
3. Fixes completed this round still go into issue_log as usual.
4. Give the user a one-line resume command: "New session opener: `Continue per <plan path>; first read <handoff path> and issue_log`."
