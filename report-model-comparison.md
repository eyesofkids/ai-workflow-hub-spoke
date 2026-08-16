# The same ticket, dispatched seventeen times

There is only one reason to dispatch a review: **to find the problems you cannot see yourself.**
So there are only two dimensions on which a model can be judged for this job — **how much it
finds**, and **whether what it says is true**.

This test set out to answer three questions:

1. **How much does what different models find actually differ?**
2. **Are some models more accurate than others?**
3. **Is one run enough?**

The conclusion first: **coverage has no relationship to a model's price, its tier, or its
reasoning effort — and neither does factual accuracy.** That has a direct consequence: **once a
cheap model reaches the same coverage, an expensive high-end model has no remaining reason to be
used for review.** Here is the data.

---

## How it was tested

| Item | Detail |
| --- | --- |
| Material | A section of a design document from a real project (when permissions are checked + API design), not a toy example |
| Shape | **The same ticket dispatched seventeen times, sixteen of them successful** — thirteen external (Anthropic ×3 / OpenAI ×4 / DeepSeek ×3 / Gemini ×3) and four in-process |
| Controls | The material, the questions, the read allowlist, and the lens definitions were **reused verbatim, verified with `diff`** |
| Baseline | **19 findings** — every one of them opened and verified by me as genuinely holding. That is the denominator |
| Total cost | **$2.5186** |

**Reusing one ticket verbatim is the only thing that makes this test worth anything.** Let a
single variable slip and every comparison below stops counting.

---

## 1. Coverage: cheap models reach the same level

| Model | Hits / 19 | Cost |
| --- | ---: | ---: |
| In-process `opus-5` (single model) | **18** | subscription |
| **External `deepseek-v4-flash`** | **14** | **$0.0095** |
| External `opus-5` (single model) | 14 | $0.5431 |
| External `gpt-5.6-sol` | 13 | $0.8320 |
| External `gpt-5.6-terra` | 10 | $0.2155 |
| External `gpt-5.6-luna` | 8 | $0.0255 |
| External `gemini-3.6-flash` | 7 | $0.1802 |
| **External `sonnet-5` (single model)** | **6** | **$0.2468** |
| External `gemini-3.5-flash-lite` | 5 | $0.0287 |

**Look at the second and third rows: `deepseek-v4-flash` and external `opus-5` both scored
14/19.**

This is not "the cheap one is better value" — **on this job they found the same amount.** And
coverage is the only thing a dispatched review really cares about: you want the problems
surfaced, not a beautifully written report.

There is something even blunter in the same table: **`sonnet-5` got 6, eight fewer than
`deepseek-v4-flash`.** It sits a tier above it, at 26 times the price.

**That is what "no remaining reason to be used" means.** Not that opus is bad — 14 externally
and 18 in-process is real capability. But when a model costing two orders of magnitude less
reaches the same coverage on the same ticket, **the question "why pay for the expensive one" has
no answer left.** Review is not composition. It does not need better prose or deeper reasoning;
it needs the 19 problems dug out — and the cheap model can do that.

### About that first row: in-process dispatch

In-process `opus-5` took the highest score of the whole test, 18/19. **That number is real; do
not use this test to argue that in-process dispatch does not work.**

But two things have to be read alongside it.

**The context injection was on the small side this time.** An in-process spoke carries an opening
context it cannot switch off — measured here at roughly **8,700 tokens** (the harness floor plus
the project's specification documents), against a system prompt of **714 characters** for the
external path. This project's specification is not large, so the interference was limited. Point
it at a project with a sprawling specification and that floor inflates immediately.

**And it inflates in a direction that is not intuitive.** From the same test, a counter-intuitive
finding: all three in-process spokes read files inside the target project, **yet what they were
fed was the specification of the project the conversation started from** — **injection depends on
which directory you dispatch from, not on where the material lives.** Dispatching the same ticket
from different directories differed by about 3×.

**And it does not just take up room.** In a separate, deliberately poisoned run — five false
statements contradicting the code were planted in the project's specification — the spoke **went
and reviewed those too**: read the code, compared, and reported that those sentences had no
counterpart in it. It was not fooled, but **it spent turns and tokens verifying them, and that
effort should have gone to the material under review.** **"Not fooled" is not the same as "not
affected."**

**And that was `opus-5`; only that one model was tested in that round.** With a weaker model there
is **no guarantee it goes back to verify** — it may simply believe what it is told. So injected
context is two different burdens depending on the model: **the strong one wastes effort refuting
it, the weak one may be led by it.** Both are problems; they merely take different shapes.

### The second problem: you cannot see it

The very first round of this test hit the most extreme form of it. The in-process request asked
for `opus-5` and `sonnet-5`; **what actually ran was Haiku** — the model was silently overridden,
discovered only afterwards by reading the transcript, and the whole data set was voided (the
original records were kept as evidence).

The external path cannot do that to you: **the dry-run report prints each spoke's provider and
model before any money is spent**, and afterwards the raw requests and responses land on disk
along with token counts and cost. Every step is checkable. In-process dispatch draws on
subscription quota, and **there is not even a published definition of how its tokens are counted**
— in this test's tables, the cost column for the in-process rows can only say "subscription",
which is not comparable to the external figures at all.

**The relationship between the two problems is that the second makes the first undiagnosable.**
You suspect that context is affecting review quality, but you cannot see what was actually
received, which model ran, or what it cost — **you cannot even measure it.**

So this test's position on in-process dispatch is: **not that it fails, but that it is
unnecessary.** That context does nothing for independent review — it cannot be switched off,
cannot be inspected, and buys no independence. When what you want is an independent judgment, the
less injected the cleaner.

---

## 2. Three explanations that sound reasonable, and all fail

### "Isn't it just reasoning effort?" — No

At first it certainly looked that way: three models on `high` landed at 12–13, two on `medium` at
4–6, and the line fell neatly along effort.

**Then I set those two to `high` as well, and the line disappeared.** The `high` group now spans
**5, 6, 7, 8, 10, 12, 13, 14, 14, 14, 18** — the entire range.

The original tidiness was an artifact: the low scorers among those six happened to be the ones
running `medium`, so effort co-varied perfectly with everything else and could not be separated
from it.

### "Then it's the high-end versus lightweight tier?" — Also no

First, what "tier" means here. **No vendor uses a word like "flagship"** in its own materials;
they describe capability and positioning. Anthropic, for example (official documentation, checked
2026-08-16): `opus-5` is "For complex agentic coding and enterprise work", `sonnet-5` is "The best
combination of speed and intelligence" ($2/$10, 40% of opus-5) — **different tiers.**

| Tier | Cells | Hits / 19 |
| --- | --- | ---: |
| High-end | `opus-5` (18 in-process / 14 external), `gpt-5.6-sol` 13, `deepseek-v4-pro` 11 | **11–18** |
| Balanced | `sonnet-5` (6 external / 5 in-process), `gpt-5.6-terra` 10 | **5–10** |
| Lightweight / fast | **`deepseek-v4-flash` 14**, `luna` 8, the `gemini` models 4–7, `haiku` 5 | **4–14** |

**Look at the overlap between the first and third rows: `deepseek-v4-flash` scored 14, and the
bottom of the high-end band is 11.** A lightweight model lands above the middle of the high-end
range — and above the high-end model from its own vendor.

The tier split is punched through from below. And the `sonnet-5` cells (5–6) make a second point:
**paying one tier up does not guarantee one tier more output.** It costs 26 times what
`deepseek-v4-flash` costs and found eight fewer.

### The cleanest comparison: same vendor, same ticket, only the model swapped

DeepSeek places `v4-flash` in the lightweight/fast tier; the high-end model of the same generation
is `v4-pro`:

| | `deepseek-v4-flash` | `deepseek-v4-pro` |
| --- | ---: | ---: |
| Hits / 19 | **14** | **11** |
| Cost | $0.0095 | **$0.1529** |

**Only the model changed. The high-end one costs 16 times as much and found three fewer.**

---

## 3. The second dimension of quality: is it right?

Coverage is only "how much it found". The other dimension is **whether what it reported holds** —
a report full of false positives is a burden however long it is, because you have to go and check
every line of it.

This axis is **just as unrelated** to price, and to volume:

- The most expensive cell ($0.4174) made **zero errors**
- Of the two cheapest cells, one made **zero errors and corrected a false positive shared by four
  other cells** ($0.0095)
- The other cheap one made **three wrong calls** ($0.0069)

**Cheap does not mean careless, and expensive does not mean careful.** That $0.0095 cell not only
said nothing wrong, it caught a mistake four other configurations made together — including ones
costing dozens of times more.

**So both dimensions of quality are decoupled from price.** That is the complete reason a
high-end model loses its value for review work: it neither found more nor spoke more accurately.

---

## 4. One run is not enough — and "only model X found it" is usually an illusion

Every configuration above was run once. So I ran a separate experiment: **does repeating the same
cell accumulate anything?**

| Model | Verbatim reruns | Then shuffling the read allowlist | Behavior |
| --- | --- | --- | --- |
| `gpt-5.6-luna` | union of 3 runs: **9** | union of 5: **11** (+2, one of them critical) | **Converges**; needs a shuffle to unlock more |
| `gpt-5.6-terra` | union of 3 runs: **10** | union of 5: **11** (+1) | **Fully converged** — 10/9/10, the union equal to the best single run |
| `deepseek-v4-flash` | **union of 5 runs: 18** | union of 7: 18 (+0) | **Varies on its own**; rerunning pays immediately |

Two things.

**1. Rerun behavior differs completely between models.** The two OpenAI models return nearly
identical answers on a rerun (`terra`'s second and third runs matched item for item), and
**only shuffling the order of the read allowlist gets anything new out of them**;
`deepseek-v4-flash` needs no such thing, because the order in which it reads varies anyway.

**2. A single result is less stable than you would think.** Across five samples of
`deepseek-v4-flash`, **only 7 findings appeared every time**, and 3 appeared exactly once — one of
them a critical one.

### A concrete example of where a "unique finding" comes from

Finding 17 of the 19 (critical) was, across the eleven configurations at the time, **found only by
in-process dispatch** — every external cell missed it, including external `opus-5`. The natural
reading is that this is an advantage of in-process dispatch, something about the tooling or the
carrier.

**Then `deepseek-v4-flash` found it on the fifth run.**

The difference was not capability. It was that **each external cell had been run once.** So:

> **Every claim of the form "only model X can find this" should be read as "that run happened to
> draw it."**

### Several cheap heads beat one expensive one

This section, taken with the previous ones, is where the conclusion actually lands.

`gpt-5.6-sol` scored 13/19 in a single run — the top group among the external cells — for $0.8320;
`gemini-3.6-flash` got 7 for $0.1802, at two to three times the unit price of Flash-Lite in the
same family (per million tokens: promotional $0.75/$3.75, **reverting to the standard $1.50/$7.50
after 2026-12-31**, against Flash-Lite's $0.25/$1.50; Google's official pricing page, checked
2026-08-16). Models at that price point **may genuinely do well in a single run** — no need to
deny it.

**But review is an application that lets you run many times.**

| | Coverage | Cost |
| --- | ---: | ---: |
| `gpt-5.6-sol`, one run | 13/19 | $0.8320 |
| **`deepseek-v4-flash`, union of five runs** | **18/19** | **about $0.05** |

**Five cheap runs found 18; one expensive run found 13.**

That is the whole point: **strong single-run performance is only an advantage in applications
where you get one run.** Review is not one of those. Its output is a list of problems, and **lists
merge**; nor is there any latency requirement — five runs instead of one costs you a few more
minutes of waiting.

**In an application that allows repeated sampling, spending the budget on single-run performance
is spending it in the wrong place.**

---

## What to do in practice

- **Do not pick a model by price tier.** Coverage does not track tier — lightweight
  `deepseek-v4-flash` scored 14, above the middle of the high-end band (11–18)
- **Run a cheap model several times and take the union; the coverage beats an expensive model run
  once.** Five runs of `deepseek-v4-flash` union to **18/19**, higher than any single cell in the
  test (best external single run: 14). **So even "the high-end model has a higher ceiling" does
  not hold** — the ceiling is not in the model, it is in the number of samples
- **If you use OpenAI models, remember to shuffle the read allowlist between reruns**, or you will
  get the same answer back
- **Mix vendors.** Some of the 19 findings were caught only by particular models — mostly a
  sampling effect, but mixing vendors is itself another way of adding samples

---

## Why a small test can still say something

One design document, 19 findings, one run per configuration — with a sample that small, what
entitles anyone to a conclusion? Three reasons.

### 1. This is a test of the small revealing the large, and an easy target is the best filter

The material is **an implementation plan for member CRUD** — a thoroughly generic problem with no
domain knowledge required to read it.

**If a model cannot find the holes in a plan like that, what would you expect from it on a harder
project?**

And the reverse case does not exist: **there is no model that fails on the easy material and
succeeds on the hard.** Difficulty does not run backwards. So the low-scoring cells would only go
lower on harder material, never higher.

**An easy target also removes a confound** — nobody can say "the question was too hard, that's why
everyone did badly." One model in this round scored 18, which proves the findings were there to be
found.

### 2. "It did badly this time, it'll do better next time" cannot explain a low score — and this was measured

The rerun experiment in section 4 measured exactly that: `gpt-5.6-terra` scored **10, 9, 10** over
three runs, and `gpt-5.6-luna`'s second and third runs **returned the same nine items.**

**These models behave stably; rerunning does not suddenly make them better.**

And if a model really did swing between good and bad, **that would be the worse problem**: you
would never know whether this dispatch got you the good run or the bad one. Review needs
predictable output, not the occasional pleasant surprise.

**Both roads lead to the same place**: either this is its level (not suitable), or it is erratic
(less suitable still).

### 3. This test answers one question only: suitability as a review spoke

**The ones that did well are suited to this job; the mediocre and poor ones are not.**

**This says nothing about anything else these models can do.** Writing code, writing prose,
conversation, reasoning, multimodal work — those are separate evaluations, and this test does not
speak to them, nor is it entitled to.

---

## Where this test applies

What it is, plainly: **one simple test.**

| | |
| --- | --- |
| Scenario | Review of a **small design document** **before implementation** — not code review, not copy-editing |
| Scale | 19 findable holes |
| Metric | **Total coverage** (how many of the 19 were found) |

**"Total coverage" is a choice, not the only possible metric — and with a different metric the
conclusions have to be recomputed.**

Score it by **how many of the critical findings were caught** and the ranking changes. The three
critical ones were distributed like this:

| Cell | Critical | How |
| --- | :-: | --- |
| **In-process `opus-5`** | **3/3** | a single dispatch |
| **External `deepseek-v4-flash`** | **3/3** | **union of five runs** — one of them appeared in only 1 of 5, caught on the fifth |
| External `opus-5` | 2/3 | single run; the one it missed is that 1-in-5 finding |

**The same model, carried differently, differs by one critical finding** (3/3 in-process, 2/3
external) — which is harder to explain by "model capability" than the differences between models
are.

And the two cells with the highest total coverage (both 18/19) part ways here too: in-process
`opus-5` got there in one run, `deepseek-v4-flash` needed five; **both missed finding 19**, which
to date only one cell has ever found.

**If your situation does not allow five runs, or if missing one critical problem is expensive,
every conclusion above has to be weighed again.**

**What to actually do depends on your project and your environment** — how large the documents
are, how dense the holes are, how long you can wait, what it costs you to miss one. This test
tells you which intuitions do not hold; it is not a configuration to copy.

### Models keep being released — doesn't that make this test endless?

While this was being written, `gemini-3.7-flash` shipped (same price as 3.6; official pricing
page, checked 2026-08-16). **Any ranking of "which model is strongest" expires within weeks.**

And rankings are not the only thing that expires — **the vendor's own description of a given model
changes too.** In its launch announcement on 2026-07-21, `gemini-3.6-flash` was "Our **workhorse**
model that delivers better coding, knowledge work, and multimodal performance." Three weeks later,
when 3.7 shipped, the official model page called it "Our **previous-generation** Flash model"
(both from Google's official pages, checked 2026-08-16). **Same model, not one bit of capability
changed, and the positioning changed first.**

Which is exactly why **rankings are not worth chasing**: half of what moves is marketing language.

But this test's core conclusions **are not a ranking; they are negative** — price does not explain
coverage, tier does not, effort does not. **Conclusions of that kind say "these variables have no
explanatory power", and a new model release does not invalidate them.**

The strategy does not expire either: **run a cheap model several times and take the union.** It
depends on no particular model; a new release only changes which one "the cheap one" is.

**So whether to re-run this depends on what you want from it**: if you want a ranking, you will
never be finished; if you want to know which intuitions to stop trusting, once is enough.

Other boundaries:

- **A single piece of material.** Two sections of one design document. With different material the
  ranking could well differ
- **The models were "whatever was to hand", not a designed sample.** No vendor was covered fully —
  no Fable 5 on the Claude side, no Pro-tier model on the Gemini side. **So any vendor's score
  represents only the models actually tested, not the vendor.** The Gemini cells at 4, 5 and 7
  especially cannot be read as "Gemini is weak" — all three were Flash and Flash-Lite class
- **The denominator of 19 is mine.** Every one was opened and verified as genuine, but the list is
  not guaranteed exhaustive — there may be a twentieth that no cell found
- **The in-process cells draw on subscription quota and cannot be compared directly to the
  external figures.** The token accounting differs as well
- **This is the state of the models in August 2026.** Models will be updated and the numbers will
  age
- **Most of this test's conclusions are negative** — effort does not explain it, tier does not,
  price does not. **It tells you which intuitions are wrong; it does not hand you a rule that says
  "use this one."** If you genuinely have to choose, run a few cells against your own material
