# CogScroll — Build Spec

This is the spec for building **CogScroll** as a Flutter app. It turns the working
React/HTML prototype in [`docs/design/`](design/) into a buildable Android app, structured
on the same lines as the published [Tasks on Time](https://github.com/stuart-bradley/tasks-on-time)
app. It is the source of truth for *what to build*; [`docs/design/DESIGN.md`](design/DESIGN.md)
is the source of truth for *how it looks and behaves*; when a detail here is ambiguous, the
prototype's behaviour (`docs/design/CogScroll.html` + `cs-*.jsx`) is the tie-breaker.

The milestone/issue breakdown lives in [`docs/GITHUB_ISSUES.md`](GITHUB_ISSUES.md).

## Locked decisions

| Decision | Choice |
|---|---|
| Platform | **Android only** (iOS a possible later port) |
| State management | **Riverpod** (`riverpod_generator`) |
| Analytics storage | **Drift** (consistent with the scaffold) |
| Trial enforcement | **On-device clock + Android Auto Backup**; purchase entitlement **Play-restored, no backend** |
| Monetization | Free install → **28-day** trial → one-time **£4** unlock (no subscription, no ads) |

---

## 1. Requirements

- **R1 — Nine games, six domains.** Working Memory, Processing Speed, Attention & Inhibition,
  Mental Flexibility, Spatial Reasoning, Sustained Attention. (Games → domains in §7.)
- **R2 — On-device, local-first.** No account, no backend, no network for app function.
  (Billing uses Google Play Billing; still no server of ours.)
- **R3 — Onboarding baseline.** First run plays one short game per domain and seeds all six
  scores, then reveals the radar.
- **R4 — Adaptive daily "Today" set.** 4–5 games per calendar day, weighted toward weaker
  domains, no game repeated, regenerated when the date changes.
- **R5 — Progress dashboard.** Six-spoke radar (current scores + dashed baseline ghost) plus
  a per-domain row: sparkline + trend mark + 0–100 score.
- **R6 — Settings.** Daily reminder (toggle + time), membership/trial state, redo baseline
  (wipes analytics, confirmed), export/import JSON backup.
- **R7 — Pure black-&-white, motion-led design.** One font (Space Grotesk), six flat shapes,
  no colour anywhere, colour-blind-safe. Faithful to `DESIGN.md`.
- **R8 — Monetization.** Free install, 28-day trial, then a blocking one-time £4 unlock that
  restores across reinstall / device on the same Google account.
- **R9 — Android release.** Play Store via a CI/CD + fastlane pipeline mirroring Tasks on Time.

---

## 2. User stories (acceptance criteria)

| ID | Story | Acceptance | Reqs |
|---|---|---|---|
| US-1 | As a new user I complete a ~5-min baseline so I see my six starting scores. | After the baseline runner finishes, all six domains have a score and the radar is revealed; `onboarded` is set. | R3,R5 |
| US-2 | As a returning user I tap "Today" and play 4–5 games back-to-back without choosing. | The Today hero shows the day's set; the runner plays them in sequence and ends on a completion screen. | R4 |
| US-3 | As a user the app focuses my weaker domains over time. | The picker weights weak domains higher (§5 `pick()`); focus dots mark weighted picks. | R4 |
| US-4 | As a user I see current vs baseline on a radar and per-domain trends. | Dashboard renders the radar with a dashed baseline ghost + per-domain sparkline, trend mark, and score. | R5 |
| US-5 | As a user I play any single game from the catalog whenever I want. | Home lists all nine games grouped by domain; tapping launches the game standalone. | R1 |
| US-6 | As a user I get correct/incorrect feedback via motion, never colour. | Correct → stimulus-conforming success motion; wrong → shake. No hue used. | R7 |
| US-7 | As a user I set a daily reminder time and get a local notification. | Toggling on + setting a time schedules a daily local notification at that time. | R6 |
| US-8 | As a user I export my progress to a JSON file and re-import it. | Export writes a JSON snapshot; import restores it and the dashboard reflects it. | R6 |
| US-9 | As a user I redo my baseline (after confirming) and my analytics reset, but my trial/purchase do not. | Confirmed redo clears analytics (incl. `onboarded`) and relaunches onboarding; `trialStart`/`purchasedCache` untouched. | R6,R8 |
| US-10 | As a new user I use everything free for 28 days. | No gating while `elapsed < 28 days` and not purchased. | R8 |
| US-11 | As a user past 28 days I hit a paywall and can unlock everything forever for £4. | When `expired && !purchased`, a blocking overlay appears; purchase dismisses it permanently. | R8 |
| US-12 | As a paying user I reinstall / switch device on the same Google account and my unlock restores automatically. | On launch `restorePurchases()` re-grants entitlement with no repurchase. | R8 |
| US-13 | As a colour-blind user I can play every game because nothing relies on hue. | Every mechanic/feedback is distinguishable in greyscale. | R7 |

---

## 3. Architecture

### 3.1 Stack

Flutter (Android-only). Dependencies mirror Tasks on Time's major versions:

| Package | Use |
|---|---|
| `flutter_riverpod` + `riverpod_annotation` + `riverpod_generator` | State + codegen |
| `drift` + `drift_flutter` | Analytics DB |
| `go_router` | Navigation |
| `in_app_purchase` | One-time unlock (entitlement = Play) |
| `flutter_local_notifications` + `timezone` | Daily reminder |
| `shared_preferences` | Flags, per-game state, `trialStart` (Auto-Backup-able) |
| `share_plus` + `file_picker` + `path_provider` | Export / import JSON |
| `package_info_plus` | Version display |
| `very_good_analysis` | Lints |
| `patrol_finders` (dev) | E2E |
| `build_runner`, `drift_dev`, `riverpod_generator`, `custom_lint`, `riverpod_lint` (dev) | Codegen + lint |

**Dropped vs Tasks on Time:** `dynamic_color` (the app is fixed pure-mono — no Material You),
`home_widget`, `flutter_staggered_grid_view`. **Added:** `in_app_purchase`. Carry forward
Tasks on Time's Android Gradle pinning notes (AGP 9 / `file_picker` 10.x / Kotlin plugin
constraints) when scaffolding.

**Font:** bundle **Space Grotesk** (SIL OFL) as an asset under `assets/fonts/` (local-first —
no runtime fetch). Weights 400/500/600/700.

### 3.2 `lib/` layout (mirrors Tasks on Time)

```
lib/
  core/
    ui_kit/      # Shape painter (6 shapes), Intro, RoundEnd, WideButton, Progress,
                 #   Countdown, TopBar, Radar
    theme/       # mono tokens, Space Grotesk text styles
    motion/      # AnimationController feedback: bloom, pulse, surge, shake, pop
    analytics/   # Drift DB + DAOs, AnalyticsService (recordResult/EMA/trend/ghost),
                 #   export/import
    scoring/     # pure normalize() — no Flutter imports
    billing/     # EntitlementService (in_app_purchase)
    time/        # Clock abstraction
    routing/     # go_router config
  features/
    games/<game>/   # one folder per game: <Game>Engine (pure) + <Game>Screen (widget)
    baseline/       # onboarding runner (CS.Baseline)
    session/        # adaptive Today runner + picker (CS.Session)
    dashboard/      # radar + per-domain trends (CS.Dashboard)
    settings/       # reminders, membership, redo baseline, export/import (CS.Settings)
    home/           # Today hero + catalog (CS.Home)
    paywall/        # trial-end overlay (CS.Paywall)
  main.dart
test/               # unit + widget, mirroring lib/
integration_test/   # patrol E2E
```

### 3.3 React prototype → Flutter mapping

| Prototype (`docs/design/`) | Flutter home |
|---|---|
| `cs-core.jsx` (Shape, Bloom/Pulse, TopBar, WideButton, Progress, Countdown, Intro, RoundEnd, Label, store) | `lib/core/ui_kit/` widgets + `CustomPainter` shapes; `lib/core/theme/` tokens; `lib/core/motion/`. `store` → Drift + `shared_preferences`. |
| `cs-data.jsx` (DOMAINS, normalize, recordResult/EMA, trend, baseline ghost, trial, export/import) | `lib/core/analytics/` + `lib/core/scoring/` + `lib/core/time/clock.dart` |
| `cs-radar.jsx` | `lib/core/ui_kit/radar.dart` (`CustomPainter`) |
| `cs-nback/memory/attention/flex/speed.jsx` (9 games) | `lib/features/games/<game>/` — pure engine + widget |
| `cs-onboarding.jsx` / `cs-session.jsx` | `lib/features/baseline/` / `lib/features/session/` |
| `cs-dashboard/settings/home.jsx` | `lib/features/dashboard|settings|home/` |
| `cs-paywall.jsx` | `lib/features/paywall/` + `lib/core/billing/` |
| `cs-app.jsx` (Stage 390×844 frame + router) | `main.dart` + `lib/core/routing/`; **drop the fixed frame** — the device is full-screen. Keep the **paywall overlay** behaviour (mounted above everything when `expired && !purchased`). |

### 3.4 Per-game pattern

Each game = a **pure Dart engine** + a presentation widget.

- The **engine** owns the loop: timers, current trial, the staircase, accumulated results.
  No Flutter imports → fully unit-testable. It exposes phase + state and callbacks
  (`start`, a tap/pick/respond entry, `resolve`, `advance`, `finish`); the widget renders
  from engine state and forwards input. This mirrors the prototype's engine/UI split and
  **avoids its documented stale-closure bug class by construction** (Dart engine state is
  real state, not a captured closure).
- **Phases:** `intro → playing → round`. `intro` uses the shared `Intro`; `round` uses the
  shared `RoundEnd` (unless running inside a runner — see §3.5).
- On `finish()` the engine computes the raw metric, calls
  `AnalyticsService.recordResult(domain, normalize(key, raw))`, and persists any per-game
  state (staircase param + last-metric for the delta).

### 3.5 Runner (`baseline`) contract

The baseline (onboarding) and Today session share one **runner**. A game can be driven by a
runner via an injected `RunnerContext` (the prototype's `baseline` prop):

- When present: the game **hides its own TopBar** (the runner draws a unified header with
  progress + Skip), runs an **abbreviated length** if the runner specifies `trials`/`points`,
  and on `finish()` calls `runner.onDone(normalizedScore)` **instead of** showing `RoundEnd`.
  The runner's Skip → `runner.onSkip()`. `recordResult` fires either way (so both baseline
  and sessions feed the dashboard).
- **Only six games support the runner** and appear in baseline/session: `reaction`,
  `flanker`, `gonogo`, `nback`, `corsi`, `trails`. The other three (`digitspan`, `stroop`,
  `taskswitch`) are **catalog-only** — playable from Home, `recordResult` on finish, never in
  a runner.

### 3.6 Theme

Single fixed `ThemeData` (no light/dark toggle — mono is mono). Tokens from `DESIGN.md`:

| Token | Value | Use |
|---|---|---|
| `bg` | `#FFFFFF` | surface |
| `fg` | `#111111` | ink / shapes / fills |
| `sub` | `rgba(17,17,17,0.42)` | secondary text |
| `faint` | `rgba(17,17,17,0.2)` | hints, disabled |
| `line` | `rgba(17,17,17,0.14)` | hairlines, idle cells |
| `panel` | `#F4F4F4` | inset wells (keypad, idle grid cells) |

Space Grotesk everywhere; **tabular figures** for metrics/counters; tracked uppercase
micro-labels (`letter-spacing ≈ 0.22em`) for chrome. Big metric on RoundEnd (~92 logical px).

### 3.7 Motion (feedback)

Drive via `AnimationController` + `CustomPainter`. The success motion **conforms to the
stimulus**:

| Motion | When | Form |
|---|---|---|
| Ring bloom | correct, round stimulus (n-back hit, go/no-go go) | concentric circle outlines expand + fade |
| Square pulse | correct, square / grid cell | two rounded-square outlines emanate, staggered |
| Directional surge | correct, Flanker | the arrow row drives in the answer direction |
| Shake | any wrong answer | stimulus becomes an outline and jitters L–R |
| Pop / bounce | stimulus entrance (reaction stimulus, n-back appear) | quick scale-in |

Rules: **the stimulus stays visible for the whole feedback motion** (blank only *between*
trials — a known prototype bug hid it early; do not reintroduce). Correct rejections stay
quiet where withholding is the action, **except** Go/No-Go's correct withhold, which still
gets a square success motion so it never feels like nothing happened.

---

## 4. Data models

> The prototype keeps everything in `localStorage` under `cogscroll:<key>`. In Flutter we
> split: **Drift** for the analytics that benefit from history/queries; **shared_preferences**
> for everything else (flags, per-game state, trial). The export/import JSON keeps the same
> logical keys so backups stay compatible.

### 4.1 Drift (analytics)

The prototype's `domains` store is `{ domain: { score, history:[{t,score}] } }`. Modelled as:

- **`domain_scores`** — `domain` (text PK, one of the six), `score` (real, 0–100). EMA:
  `score = round(old*0.6 + new*0.4)`; the **first** result for a domain seeds it directly
  (`old == null → score = new`).
- **`score_history`** — `id` (auto), `domain` (text FK), `recorded_at` (datetime), `score`
  (real, 0–100). DAO **prunes to the most-recent 60 per domain** after each insert.

Derived (no stored column):

- **Baseline ghost** = `score_history` ordered by `recorded_at`, **first** row per domain
  (the prototype's `baselineScores()`).
- **Sparkline** = that domain's history scores in order.
- **Trend** = `domainTrend` (§5).

Migrations + in-memory `NativeDatabase.memory()` for tests, exactly as Tasks on Time.

### 4.2 shared_preferences

| Key | Type | Notes |
|---|---|---|
| `onboarded` | bool | baseline completed. **Cleared by redo baseline** (see §4.4). |
| `baselinePrompted` | bool | first-run prompt shown. |
| `session` | JSON `{date, steps:[gameId], done:[bool]}` | today's adaptive set; regenerates when `date` changes. |
| `notify` | bool | daily reminder enabled. |
| `notifyTime` | `{h, m}` | reminder time. |
| `trialStart` | int (ms epoch) | set once on first launch. Auto-Backup-able. |
| `nback-n`, `flanker-level`, `gng-level`, `switch-level`, `trail-a-level`, `trail-b-level`, `stroop-level` | num | persisted difficulty **level** (uniform two-consecutive ±1 staircase, §7). |
| `nback-streak`, `flanker-streak`, `gng-streak`, `switch-streak`, `trail-a-streak`, `trail-b-streak`, `stroop-streak` | num | signed **consecutive-qualifying-round** counter driving the two-consecutive ±1 rule. |
| `corsi-span`, `digit-span-fwd`, `digit-span-bwd` | num | persisted span **level** (span games store `best`; their consecutive counters are within-play, not persisted). |
| `nback-acc`, `flanker-acc`, `gng-acc`, `switch-acc`, `trail-a-time`, `trail-b-time`, `stroop-interference`, `rt-avg` | num | **display-only** last metric, for the RoundEnd delta (not the dashboard). |
| `purchasedCache` | bool | **cache** of Play entitlement, not authoritative (see §6). |

### 4.3 Scoring (pure functions; level/mode-aware)

`normalize(key, raw) → 0–100`, piecewise-linear (`piece()`), clamped, rounded. A table whose
score column **descends** as raw ascends encodes a lower-is-better metric, so **"up" always means
better** downstream. Restored within-game difficulty (§7) makes scoring **level/mode-aware**: a
given accuracy/time scores higher at a harder level (generalising `nback`'s long-standing
`eff = acc + (n-2)*15`). `raw` is therefore a record for the leveled games.

| key | raw | mapping (`eff`/`spt`, then `piece` over `[rawX, score]`, raw ascending) |
|---|---|---|
| `nback` | `{acc, n}` | `eff = acc + (n-2)*15`; `[[40,15],[60,35],[75,58],[85,78],[100,100]]` |
| `flanker-acc` | `{acc, level}` | `eff = acc + (level-1)*10`; `[[60,10],[85,35],[90,58],[95,80],[100,100]]` |
| `gng-acc` | `{acc, level}` | `eff = acc + (level-1)*10`; `[[60,10],[85,38],[92,62],[97,84],[100,100]]` |
| `switch-acc` | `{acc, level}` | `eff = acc + (level-1)*10`; `[[50,12],[70,40],[82,60],[90,78],[100,100]]` |
| `stroop` (ms ↓) | `{interferenceMs, level}` | `eff = interferenceMs - (level-1)*15`; `[[40,100],[80,82],[150,55],[200,30],[300,8]]` |
| `corsi-span` | `num` | `[[2,10],[3,25],[5,55],[6,68],[7,82],[9,100]]` |
| `digit-span` (fwd) | `{span, mode:'fwd'}` | `[[3,15],[4,30],[6,55],[7,68],[8,82],[10,100]]` |
| `digit-span` (bwd) | `{span, mode:'bwd'}` | `[[2,15],[3,30],[4,50],[5,68],[6,82],[8,100]]` |
| `rt-avg` (ms ↓) | `num` | `[[180,100],[220,82],[260,62],[300,45],[350,28],[450,8]]` |
| `trail-time` (s/target ↓, A) | `{seconds, count, mode:'a'}` | `spt = seconds/count`; `[[1.0,100],[1.7,82],[2.5,58],[3.3,42],[5.0,22],[7.5,5]]` |
| `trail-time` (s/target ↓, B) | `{seconds, count, mode:'b'}` | `spt = seconds/count`; `[[1.8,100],[3.0,82],[4.5,58],[6.0,42],[9.0,22],[13.5,5]]` |

`eff`/`spt` are clamped into the table's range before interpolation. The lift/credit constants
(`*10`, `*15`) and the Stroop / Trail / backward-Digit-Span tables are **tunable** but anchored to
the product spec's published norm bands (e.g. TMT-A good <20 s, TMT-B good <45 s; Stroop
interference good <80 ms; backward digit span good 6+). **Every table + `eff`/`spt`/mode branch
must be unit-tested** — endpoints, midpoints, out-of-range clamping, and **level monotonicity**
(higher level, same raw ⇒ score ≥).

### 4.4 Redo baseline (analytics reset)

Redo-baseline removes: `domains`, **`onboarded`**, and **every per-game key** from §4.2 — the
difficulty `*-level` + `*-streak` keys, the span keys (`corsi-span`, `digit-span-fwd`,
`digit-span-bwd`), and the display-only last-metric keys (`nback-acc`, `flanker-acc`, `gng-acc`,
`switch-acc`, `trail-a-time`, `trail-b-time`, `stroop-interference`, `rt-avg`). In Flutter that
means: **wipe both Drift tables** + clear those `shared_preferences` keys + clear `onboarded` (so
onboarding relaunches). It does **not** touch `trialStart`, `purchasedCache`, `notify`,
`notifyTime`, `baselinePrompted`, `session`. (Wiping `score_history` clears the baseline ghost
naturally.) The exact key set is `CsStoreKeys`-defined and unit-tested.

### 4.5 Export / import

Snapshot envelope (keep compatible with the prototype):

```json
{ "app": "CogScroll", "version": 1, "exportedAt": "<ISO>", "data": { "<key>": <value>, ... } }
```

`data` is the flat set of logical keys (Drift analytics serialised back to the prototype's
`domains` shape + the shared_preferences keys). **Export** → write via `share_plus` /
file save (`cogscroll-<yyyy-mm-dd>.json`). **Import** → accept either `{data:{...}}` or a raw
`{...}`, validate, restore, return a count; throw on a malformed payload. Round-trip must be
unit-tested.

**Entitlement & trial keys never cross the backup boundary.** `purchasedCache` and
`trialStart` are **excluded from both export and import** (`CsStoreKeys.nonPortableKeys`), so a
crafted or shared backup file can neither grant entitlement nor reset/extend the trial. A
manual backup carries analytics, settings, and per-game state only — **not** trial or
entitlement state. Entitlement stays Play-restored (§6.1); trial continuity across a reinstall
is **Android Auto Backup**'s job (§6.2), not manual export/import. (This narrows the prototype,
where `purchased` was a throwaway local flag with no real billing.)

---

## 5. Adaptive picker (`pick()` / `weights()` — `cs-session.jsx`)

Per calendar day, choose **4–5 distinct domains** by weight, then a **random game per
chosen domain** (no game repeats). Weight per domain, computed against the **personal** set
of measured scores (`mean`, `min`, `range = max(max−min, 1)`), evaluated in this order:

1. unmeasured (`score == null`) → **×2**
2. else bottom 25% of personal range (`score ≤ min + range*0.25`) → **×3**
3. else below personal mean (`score < mean`) → **×2**
4. else (maintenance) → **×1**

A pick shows a **focus dot** when its weight `≥ 2`. Persist the chosen set in `session`
keyed by date; regenerate only when the date changes. Pre-baseline, the Today hero is locked
and points at the baseline. Domain selection draws **only** from the runner-capable engines
(§3.5) — `reaction, flanker, gonogo, nback, corsi, trails` — where Mental Flexibility resolves
to a Trail Making mode (A or B).

---

## 6. Monetization & trial

### 6.1 Purchase — Play-validated, no backend

One **non-consumable** managed product (id `cogscroll_lifetime_unlock`, **£4**).

- On launch: `InAppPurchase.instance.isAvailable()`; if available, subscribe to
  `purchaseStream` and call `restorePurchases()`. **Google Play is the source of truth** for
  entitlement (its on-device response is signed). Cache the result to `purchasedCache`.
- Resolution order: **billing available → `restorePurchases()` is authoritative**; billing
  unavailable (offline / no Play services) → fall back to `purchasedCache`.
- On a `PurchaseStatus.purchased` (or `restored`) event → grant entitlement, then
  `completePurchase`. This makes **US-12** (reinstall / new device on the same Google
  account) work with **no server** — entitlement is queried from Play, not stored by us.
- No server-side receipt verification (accepted for an indie one-time product; revisit if a
  backend is ever added).

### 6.2 Trial — on-device clock + Android Auto Backup

Google Play has **no** trial mechanism for a free app + one-time product (its built-in
trials are subscription-only, plus a games-only 60-min trial). So the 28-day clock **cannot**
be Play-validated without a backend or a subscription product. Therefore:

- `trialStart` set on first launch (ms epoch). `TRIAL_DAYS = 28`.
- `elapsed = floor((now − trialStart) / 86_400_000)` days; `daysLeft = max(0, 28 − elapsed)`;
  `expired = elapsed ≥ 28 && !purchased`.
- Enable **Android Auto Backup** (`android:allowBackup="true"` + backup rules that include
  `shared_preferences`) so `trialStart` survives **reinstall** on the same account — closing
  the easy "reinstall to reset" hole with no backend.

**Accepted residual leaks** (documented, fine for an indie app): (a) device clock set
backward; (b) **clear app data** resets `trialStart` (Auto Backup only restores on a *fresh
install*, not after clear-data); (c) Auto Backup disabled/unavailable. The **purchase**
entitlement is unaffected by all three (it's Play-restored, not local).

### 6.3 Paywall

A blocking full-screen overlay mounted **above** the app whenever `expired && !purchased`
(the prototype mounts `CS.Paywall` over the Stage). "Unlock · £4 once" launches the purchase
flow; on entitlement it dismisses **permanently**. The trial is **not** reset by a baseline
redo.

### 6.4 Play Console / policy checklist

- Create the non-consumable managed product; set the £4 price.
- Add **license-tester** accounts for sandbox purchase testing.
- **Disclose** the "free 28 days, then a one-time purchase" model in the store listing
  description **and** at first run (no dark patterns).
- Honour Play's refund window; no RTDN / Pub-Sub needed for a one-time product.

---

## 7. The nine games

**R** = appears in baseline/session runner (§3.5). **Within-game adaptive difficulty is
restored for every game except Reaction Time** (a deliberate baseline measure). An earlier build
draft mislabelled five games "per-round" by carrying `DESIGN.md`'s *visual* framing into the
difficulty *system*; that is corrected here. The product-spec rule — *"every game uses a
staircase or threshold-based difficulty system; the player always operates near their current
limit"* — applies throughout. Colour-bound difficulty levers are reinterpreted for mono (never
re-introducing colour); see the per-game ladders in §7.1.

The staircase is uniform: **+1 level after two consecutive rounds above the up-threshold, −1
after two consecutive below the down-threshold**, bounded per game, with the level (and its
consecutive-streak) persisted (§4.2). Span games (Corsi, Digit Span) keep their within-play ±1
on two-consecutive correct/fail and track `best`.

| id (mode) | Domain | Mechanic | Metric (normalize key) | Adaptation | R |
|---|---|---|---|---|:--:|
| `nback` | Working Memory | tap when the shape repeats N back | accuracy (`nback`, `{acc,n}`) | N **start 1**, up acc>85 / down acc<60 (cap 4) | ✅ |
| `flanker` | Sustained Attention | tap the way the **middle** arrow points | accuracy (`flanker-acc`, `{acc,level}`) | level 1→5 (§7.1) | ✅ |
| `gonogo` | Attention & Inhibition | tap circle (Go), withhold square (No-Go) | accuracy (`gng-acc`, `{acc,level}`) | level 1→5 (§7.1) | ✅ |
| `corsi` | Spatial Reasoning | repeat the flashed cell sequence | best span (`corsi-span`) | ±1 span; **grid grows 4×4→5×5 when span>6** | ✅ |
| `trails-a` *(A: numbers)* | Mental Flexibility | connect 1→N in order, against the clock | s/target (`trail-time`, `{seconds,count,mode}`) | level 1→5 = count 8→25 (§7.1) | ✅ |
| `trails-b` *(B: number/letter)* | Mental Flexibility | connect 1→A→2→B… alternating | s/target (`trail-time`, mode B) | level 1→5 = count 8→25 (§7.1) | ✅ |
| `reaction` | Processing Speed | tap the instant the shape appears | avg ms (`rt-avg`) | none — baseline measure | ✅ |
| `digitspan-fwd` *(forward)* | Working Memory | recall digits on a keypad, in order | best span (`digit-span`, fwd) | ±1 span on 2 correct / 2 fails | |
| `digitspan-bwd` *(backward)* | Working Memory | recall digits **in reverse** | best span (`digit-span`, bwd) | ±1 span on 2 correct / 2 fails | |
| `stroop` *(shape)* | Attention & Inhibition | tap the shape you **see**, not the word on it | **interference cost ms** (`stroop`, `{interferenceMs,level}`) | level 1→5 (§7.1) | |
| `taskswitch` *(shape/fill/size)* | Mental Flexibility | judge the active rule — it keeps switching | accuracy (`switch-acc`, `{acc,level}`) | level 1→5 (§7.1) | |

The runner-capable engines are `reaction, flanker, gonogo, nback, corsi, trails` (trails offers
Mode A/B as two runner-pickable entries). `digitspan` (fwd/bwd), `stroop`, and `taskswitch` are
catalog-only. `trails` and `digitspan` are each **one engine with a mode flag**, surfaced as two
`GameRegistry` entries — eleven entries from nine engines.

**Locked B&W adaptations** (mono reinterpretations — never re-introduce colour):

- **Stroop → shape-Stroop:** a word naming one shape is drawn over a *different* shape (word on a
  white plate so it stays legible); tap the shape you see. The restored difficulty escalates
  **presentation speed, shape confusability** (circle/hexagon are harder to tell apart than
  circle/cross), **swatch spacing**, and **option count** — the colour-bound "more similar hues"
  lever becomes shape confusability. The metric is the original **interference cost** (mean
  incongruent RT − mean congruent RT, congruent trials interspersed); lower is better.
- **Task Switching → shape/fill/size:** the rules are "judge the shape (circle/square)", "judge
  the fill (filled/hollow)", and — added so the top level can rotate **three rules** without
  colour — "judge the size (big/small)". Levels 1–4 use shape/fill with escalating switch cadence
  and a tightening response window; level 5 rotates all three rules.

Each game keeps full vs abbreviated (runner) lengths; the §7.1 difficulty knobs override the
prototype's fixed trial counts/timeouts. See the per-game modules in `docs/design/` for the base
visuals, timings, and sequence generation.

### 7.1 Per-game difficulty ladders (mono)

All ladders use the uniform two-consecutive-rounds ±1 staircase (§7); thresholds are tuned per
game and unit-tested.

- **N-Back** — N ∈ [1,4], start 1. Up when round accuracy >85%, down when <60%.
- **Flanker** — L1 one flanker/side, congruent · L2 one flanker/side, incongruent · L3 two
  flankers/side, incongruent · L4 + display window 500 ms · L5 + 300 ms and flanker size = target.
- **Go/No-Go** — L1 80/20 Go/No-Go, ISI 1000 ms · L2 ISI 700 · L3 70/30, ISI 600 · L4 60/40,
  ISI 500 · L5 ISI 400 + a No-Go shape more visually similar to the Go shape.
- **Corsi** — span staircase (start 3, min 2); the grid grows 4×4 → 5×5 once best span > 6.
- **Trail Making (A & B)** — target count L1 8 · L2 12 · L3 16 · L4 20 (smaller dots) · L5 25
  (small, crowded). Mode A connects 1→N; Mode B alternates 1→A→2→B…. Faster (lower s/target) ⇒
  level up.
- **Digit Span (fwd & bwd)** — span staircase; forward starts at 4 (min 3), backward at 3 (min 2).
- **Stroop** — L1 slow presentation, distinct shapes, wide spacing, fewer options → L5 fast
  presentation, confusable shapes, tight spacing, more options. Lower interference cost ⇒ level up.
- **Task Switching** — L1 rule changes every 4 trials · L2 every 2 · L3 random · L4 random +
  tighter response window · L5 three rules (shape/fill/size) rotating randomly.

---

## 8. Screens / information architecture

From `DESIGN.md`. Each screen ports from the named prototype module.

| Screen | From | Notes |
|---|---|---|
| **Home** | `cs-home.jsx` | Today hero (compact icon row + chevron, focus dots, completion checkmarks; locked pre-baseline) then the catalog of all nine games grouped by domain. |
| **Game Intro** | `cs-core.jsx` `Intro` | calm start screen: legend + mechanic text + footnote + Begin. |
| **Game Play** | per game | stimulus area + response controls + progress/countdown + feedback motion. |
| **Round End** | `cs-core.jsx` `RoundEnd` | big metric + caption + optional delta (↑/↓ vs last) + optional level-up message + Continue. |
| **Onboarding Baseline** | `cs-onboarding.jsx` | Welcome → six runner games auto-advancing (unified header, Skip) → reveal seeded radar → Home. No mid-flow resume. |
| **Adaptive Session** | `cs-session.jsx` | Today's 4–5 games back-to-back via the runner; per-game Continue/▢ Done; session-complete screen. |
| **Progress Dashboard** | `cs-dashboard.jsx` | radar (current + dashed baseline ghost + legend), then per-domain rows (sparkline auto-scaled to ≥20-pt span, trend ▲/—/▼, 0–100 score; "Not enough data yet" under 3 results). Reached via Settings → Progress. |
| **Settings** | `cs-settings.jsx` | Progress link · Reminders (toggle + mono time spinner) · Membership (trial days left / Unlock, or Lifetime access) · Assessment (start/redo baseline; redo confirms then resets) · Backup (export/import). |
| **Trial Paywall** | `cs-paywall.jsx` | blocking overlay (§6.3). |

---

## 9. Testing strategy (TDD — tests authored with each change, never deferred)

- **Inject a `Clock`** everywhere time is read; **never call `DateTime.now()` directly** — so
  trial expiry, EMA timestamps, and session-date rollover are deterministic.
- **Unit:** `normalize` (every table in §4.3, incl. clamping); EMA seeding + update;
  `domainTrend` (n<3 → none; the recent-vs-earlier split; STABLE=4 boundaries);
  `pick()`/`weights()` (the four weight tiers, distinctness, no-repeat, per-day persistence);
  trial math (`daysLeft` clamp, `expired` boundary at exactly 28 days); entitlement
  resolution against a **`FakeInAppPurchase`** (available→restore authoritative,
  unavailable→cache fallback, purchased/restored events grant); each **game engine**
  (correct/incorrect/staircase, `finish()` records the right normalized score); Drift DAOs
  in-memory incl. the **60-cap prune** and the derived baseline = first history row;
  export/import round-trip + malformed-payload throw + redo-baseline key set (§4.4).
- **Widget:** each game's core interaction + feedback motion + `recordResult` wiring; paywall
  gating (expired→overlay shown, purchased→absent); dashboard radar/sparkline/trend render
  with seeded data; settings reminder toggle/time.
- **E2E (patrol):** baseline onboarding flow; daily session flow; export → import; **paywall
  after expiry** (seed `trialStart` 28+ days back via the injected clock); purchase via Play
  sandbox / license tester.
- **CI** mirrors Tasks on Time: `just check` (codegen + analyze + format-check + test) on
  PRs; `e2e.yml` on an emulator; tag-triggered `release.yml` → fastlane → Play internal track.

---

## 10. Milestones

Full issue breakdown in [`docs/GITHUB_ISSUES.md`](GITHUB_ISSUES.md):

`M0` Scaffold (from Tasks on Time) · `M1` Core UI kit + motion + shapes · `M2` Analytics/Drift
+ scoring + Clock · `M3` Nine games (one issue each) · `M4` Radar + Dashboard · `M5`
Onboarding baseline · `M6` Adaptive Today session · `M7` Settings + reminders + export/import
· `M8` Billing + trial + paywall + Auto Backup · `M9` App icon + store assets + release.

---

## 11. Confirmed identifiers & remaining open item

**Confirmed** (user sign-off 2026-06-08 — safe to use from M0):

- applicationId **`com.stuartbradley.cogscroll`** (permanent once on Play).
- IAP product id **`cogscroll_lifetime_unlock`**; price tier **£4**.
- Display name **CogScroll**.
- Daily reminder is a **real** local notification (US-7), not the prototype's
  preference-only stub.

**Still open:**

- App store tile may use a single brand colour (the in-app pure-mono rule is unchanged) —
  open in `DESIGN.md` §9; decide at M9.
