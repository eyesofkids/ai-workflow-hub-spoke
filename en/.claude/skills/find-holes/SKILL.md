---
name: find-holes
description: Dispatch "hole-finder spokes" (sub-agents) against a plan document — the hub trims need-to-know tickets, dispatches 1–3 sub-agents with different lenses to find holes and feasibility issues, and collects an opinion list for the user to adjudicate. Usage: /find-holes <plan file path> [focus section or question]
---

# find-holes — Hole-Finder Spoke Dispatch

You are the hub. This skill hands the specified scope of a plan document to clean-perspective sub-agents to find holes. **Spokes produce opinions, not verdicts; the user decides what gets adopted.**

## Steps

1. **Read the plan document** (the file given as the argument). If the user specified a focus section or question, take only that scope; otherwise take the finalized-design sections (skip background, prior context, and references to settled facts).
2. **Assemble a need-to-know ticket**, containing only three things:
   - **The verbatim text of the sections under review** (embedded directly into the prompt — no file paths)
   - **A list of premises** (marked "premise — not under review"): the user's settled decisions from the top of the plan, and the conclusions of verified facts (one conclusion line only — no facts file)
   - **Concrete questions** (2–4 per spoke, e.g. "Does the pairing rule in §3.2 have holes under concurrency?")
   - **Forbidden content**: historical version chains, deprecated plan documents, decision-process background, any `_docs` paths. Precedents may only be given as a one-line criterion ("the yardstick, not the corpse" — see the provenance rules in AGENTS.md).
3. **Present the dispatch plan and stop for confirmation**: pick from the three lens agents according to the plan's content (all read-only):
   - `hole-finder-feasibility` (sonnet): feasibility, implementability, verify-on-cite
   - `hole-finder-safety` (opus): concurrency races, failure modes, input validation, data leaks
   - `hole-finder-cost` (sonnet): billable-call gate ordering, pre-checks, over-limit behavior

   For a plan none of the three lenses fits, fall back to the generic `hole-finder` (sonnet) and specify a custom lens in the prompt yourself. Before dispatching you **must** present the plan to the user and **explicitly ask, stop, and wait for confirmation; do not call Agent without approval**:
   - How many to dispatch (1–3)
   - Each one's agent and lens
   - Each one's model (use the agent's default; if this particular hole demands deeper reasoning, override via the `model` parameter on the Agent call to upgrade to opus/fable, with reasons)
   - A summary of the ticket contents (which sections, which premises, which questions were included)
   **Outsourced mode (optional)**: when you need a heterogeneous perspective from a non-Anthropic model, do not call Agent after confirmation. Instead, output a self-contained ticket as one block of copyable text — in addition to the ticket contents above, it must include the role definition, the `_docs/` prohibition, the output format, the four prohibitions, the fixed closing line, and the spokes to dispatch — **naming the agents explicitly** (`hole-finder-feasibility` / `hole-finder-safety` / `hole-finder-cost`, identically named on both sides) along with the count, never a bare lens description the broker has to map itself. The user pastes it into the `dispatch-broker` chat in VSCode, then pastes the collected result back. The substance of the ticket is identical to in-house dispatch; only who executes it and which vendor's model runs it differ.

   Apply the user's changes to count / models / lenses exactly as given. Dispatch only after confirmation; every prompt must contain:
   - The ticket contents (step 2)
   - The list of code files the spoke is allowed to read (only those directly related to the sections under review); explicitly forbid browsing other documents under `_docs/`
   - The output format: a list of "observation + basis (file:line or reasoning)"; it **must not** contain verdict rulings, severity grades, "should be changed to" alternative designs, or adoption recommendations; uncertainties are written as questions, not as defects.
4. **Collect: verbatim first, then synthesis**: log each spoke's report **verbatim, one by one** (labeled with its lens and model — no trimming, rewriting, or summary-only; the user must be able to see what each spoke said individually); then add a separate **"hub reading" section** that deduplicates and annotates each item with your preliminary, context-informed reading ("holds / doesn't hold + why / needs the user's ruling"). Results returned from outsourced mode follow the same rule: log the broker's audit table verbatim alongside the reports — never keep only its conclusions.
5. **After the user adjudicates**, you revise the plan document with the adopted items (the new version records only the delta). Spoke output never becomes a document version directly.

## Red Lines

- Spoke opinions must not touch "whether to do it"; if a spoke oversteps with terminate/block-type conclusions, discard the conclusion, keep only its factual part, and note this in the report.
- Do not change the plan document's status field on your own because of spoke opinions.
