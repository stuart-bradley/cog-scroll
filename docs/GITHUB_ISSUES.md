# CogScroll — Implementation Issues (M0–M9)

The seed GitHub Issues for building CogScroll, grouped by milestone. Each issue names its
scope, the prototype/spec it ports from, and **its own tests** (TDD — tests land with the
code, never deferred). Work milestones in order; within a milestone, lowest issue number
first. Spec references: [`SPEC.md`](SPEC.md); design references: [`design/DESIGN.md`](design/DESIGN.md)
+ the `cs-*.jsx` prototype modules.

> Convention: one branch + PR per issue, `Closes #N`, CI green (`just check`) before merge.
> Every issue that adds behaviour must add/extend tests.

---

## M0 — Scaffold  *(blocks everything)*

**#1 — Create the Flutter project from the Tasks on Time scaffold.**
Clone the structure of `tasks-on-time`: `pubspec.yaml` (deps per `SPEC.md` §3.1 — drop
`dynamic_color`/`home_widget`/`flutter_staggered_grid_view`, add `in_app_purchase`),
`analysis_options.yaml` (`very_good_analysis`), `justfile`, `.github/workflows/`
(`ci.yml`, `e2e.yml`, `release.yml`) + `.github/actions/setup-flutter`, `android/` Gradle
config (carry forward the AGP 9 / `file_picker` 10.x / Kotlin pinning notes),
`fastlane/Fastfile`, scripts. Set **applicationId `com.stuartbradley.cogscroll`**, display
name **CogScroll** (both confirmed). Strip all Tasks-on-Time domain code (timers,
widgets, notifications-of-timers) — keep only the empty `core/` + `features/` skeleton and a
runnable `main.dart`.
*Tests:* `just check` runs green on the empty skeleton; a trivial smoke widget test boots the
app to a placeholder home.

**#2 — Mono theme + Space Grotesk + design tokens.**
Bundle Space Grotesk (OFL) under `assets/fonts/`; declare in `pubspec.yaml`. Build the fixed
`ThemeData` and a `tokens` file with the §3.6 values (`bg/fg/sub/faint/line/panel`), text
styles (tabular figures for metrics; tracked uppercase micro-labels). No dark mode.
*Tests:* widget test asserting key token colours/text styles resolve; golden of a sample
label + metric (optional).

---

## M1 — Core UI kit + motion  *(needs M0)*

**#3 — Shape system (`CustomPainter`).** The six stimuli (circle, square, triangle, diamond,
cross, hexagon) with size/colour/outline, matching `cs-core.jsx` `Shape` + `SHAPE_NAMES`.
*Tests:* painter unit tests (paints without error at each id; outline vs fill); a golden per
shape (optional).

**#4 — Feedback motion.** `AnimationController`-driven bloom (ring), pulse (square), surge
(directional), shake (wrong), pop (entrance), per `SPEC.md` §3.7. Enforce
"stimulus stays visible for the whole motion".
*Tests:* widget tests pumping the controller — each motion runs to completion with the
stimulus present throughout.

**#5 — Shared kit widgets.** `Intro`, `RoundEnd` (value, caption, sub, delta ↑/↓, level
message, continue), `WideButton` (solid/hollow, check/cross), `Progress` (`08 / 20` +
depleting track), `Countdown` (keyed by trial), `TopBar`, `Label`. Port from `cs-core.jsx`.
*Tests:* widget tests for `RoundEnd` delta direction (up = better), `Progress` counts,
`Countdown` restart on key change, button variants.

---

## M2 — Analytics, scoring, time  *(needs M0; pairs with M1)*

**#6 — `Clock` abstraction.** Injectable clock; ban direct `DateTime.now()`. Provide a real
clock + a `FakeClock` for tests.
*Tests:* `FakeClock` advance/set.

**#7 — Scoring (`normalize`).** Pure functions porting `cs-data.jsx` §4.3 exactly (piecewise
+ clamp + round; `nback` takes `{acc,n}`; ms/seconds invert).
*Tests:* every mapping table — endpoints, an interior midpoint, below-min and above-max
clamping; `nback` effective-score lift.

**#8 — Drift analytics DB + DAOs.** `domain_scores` + `score_history` (`SPEC.md` §4.1);
migrations; in-memory test DB. DAO ops: upsert EMA score (seed-then-`round(old*0.6+new*0.4)`),
append history with **60-cap prune**, read scores, read history (sparkline), derive baseline
ghost = first history row per domain.
*Tests (in-memory):* EMA seeding + update; 60-cap prune; baseline = first row; empty-state.

**#9 — `AnalyticsService`.** `recordResult(domain, score)`, `domainScores()`,
`domainHistory()`, `baselineScores()`, `domainTrend()` (n<3 → none; recent-vs-earlier;
STABLE=4), `hasData()`. Wraps the DAOs; Riverpod providers expose `AsyncValue`.
*Tests:* trend tiers at the ±4 boundary; record→score/trend update; provider loading/data.

**#10 — Export / import + redo-baseline reset.** Snapshot envelope (`SPEC.md` §4.5) via
`share_plus`/`file_picker`/`path_provider`; import accepts `{data}` or raw, validates, returns
a count, throws on malformed. `clearAnalytics()` = wipe both Drift tables + per-game prefs +
`onboarded` (§4.4), leaving trial/purchase/reminders/session intact.
*Tests:* round-trip; malformed throw; redo clears exactly the §4.4 key set and nothing else.

---

## M3 — The nine games  *(needs M1, M2; one issue each)*

Each game: a **pure engine** (`SPEC.md` §3.4) + a widget; runner support per §3.5 where
marked **R**; `finish()` wires `recordResult(domain, normalize(key, raw))` and persists
per-game state. Port mechanics/lengths/timings from the named module.

- **#11 — Reaction Time** *(R, Processing Speed, `cs-speed.jsx`, `rt-avg`)*
- **#12 — N-Back** *(R, Working Memory, `cs-nback.jsx`, `nback`; N staircase up>85/down<60 cap 4)*
- **#13 — Flanker** *(R, Sustained Attention, `cs-attention.jsx`, `flanker-acc`; directional surge)*
- **#14 — Go / No-Go** *(R, Attention & Inhibition, `cs-attention.jsx`, `gng-acc`; correct withhold still pulses)*
- **#15 — Spatial Grid / Corsi** *(R, Spatial Reasoning, `cs-memory.jsx`, `corsi-span`; ±1 staircase)*
- **#16 — Trail Making** *(R, Mental Flexibility, `cs-flex.jsx`, `trail-time`; 1→12 timed)*
- **#17 — Digit Span** *(catalog-only, Working Memory, `cs-memory.jsx`, `digit-span`; ±1 staircase)*
- **#18 — Stroop (shape)** *(catalog-only, Attention & Inhibition, `cs-attention.jsx`, `stroop-acc`; word-on-plate over a different shape)*
- **#19 — Task Switching (shape/fill)** *(catalog-only, Mental Flexibility, `cs-flex.jsx`, `switch-acc`; rule banner switches)*

*Tests (each):* engine unit tests — correct vs incorrect resolution, staircase transitions
(where applicable), `finish()` produces the expected normalized score and persists per-game
state; a widget smoke test of the core tap/response path + feedback motion. The six **R**
games additionally: a runner-mode test (hides own TopBar, abbreviated length, calls
`onDone` instead of `RoundEnd`, still records).

---

## M4 — Radar + Dashboard  *(needs M2; M3 useful for real data)*

**#20 — Radar (`CustomPainter`).** Six-spoke radar from `cs-radar.jsx`: current polygon +
dashed **baseline ghost** + legend; filled vertex when measured, empty when null.
*Tests:* paints with full/partial/empty score maps; ghost drawn when baseline present.

**#21 — Progress Dashboard screen.** Radar + per-domain row (auto-scaled sparkline ≥20-pt
span, trend ▲/—/▼, 0–100 score, "Not enough data yet" under 3 results). Reached via
Settings → Progress.
*Tests:* widget test with seeded analytics — radar + each row render; under-3 state shows the
fallback.

---

## M5 — Onboarding baseline  *(needs M3 (the six R games), M4)*

**#22 — Baseline runner.** The shared runner (`SPEC.md` §3.5) + onboarding flow from
`cs-onboarding.jsx`: Welcome → six R games (`reaction, flanker, gonogo, nback, corsi,
trails`) abbreviated, auto-advancing under a unified header with progress + Skip → reveal
seeded radar → Home. Sets `onboarded` + `baselinePrompted`; no mid-flow resume (clean
restart). Skipped domains stay null.
*Tests:* runner advances on `onDone`, Skip calls `onSkip` and advances; completing all six
seeds six scores and sets the flags; widget/E2E for the happy path.

---

## M6 — Adaptive Today session  *(needs M3 (R games), M5)*

**#23 — Picker.** `weights()`/`pick()` per `SPEC.md` §5: 4–5 distinct domains by weight
(unmeasured ×2, bottom-25%-of-range ×3, below-mean ×2, maintenance ×1), random game per
domain (no repeats), persisted per calendar day in `session` (regenerate on date change).
*Tests:* the four weight tiers; distinctness + no-repeat; same day → same set; date change →
regenerate.

**#24 — Today hero + session runner.** Home hero (compact icon row + chevron, focus dots on
weight≥2 picks, completion checkmarks, locked pre-baseline) + the back-to-back runner reusing
M5's runner; per-game Continue/▢ Done; session-complete screen.
*Tests:* hero locked pre-baseline; runner plays the set and marks done; completion screen.

---

## M7 — Settings, reminders, backup  *(needs M2, M4)*

**#25 — Settings screen.** From `cs-settings.jsx`: Progress link · Membership (trial days
left / Unlock, or Lifetime access — wired in M8) · Assessment (start/redo baseline; redo
confirms then runs §4.4 reset) · Backup (export/import from #10).
*Tests:* widget tests — redo confirm→reset path; export/import entry points; membership
states render.

**#26 — Daily reminder (real notification).** `flutter_local_notifications` + `timezone`:
on/off toggle + mono time spinner → `notify`/`notifyTime`; schedule/cancel a **real** daily
notification (this is the one place CogScroll goes beyond the prototype's preference-only
stub — `SPEC.md` §11). Request `POST_NOTIFICATIONS`; reschedule on boot.
*Tests:* toggle schedules/cancels (fake notification service); time change reschedules.

---

## M8 — Billing, trial, paywall  *(needs M2, M7)*

**#27 — Entitlement service (`in_app_purchase`).** `SPEC.md` §6.1: `isAvailable()` →
`restorePurchases()` + `purchaseStream`; Play authoritative when available, `purchasedCache`
fallback offline; `completePurchase` on purchased/restored. Non-consumable
`cogscroll_lifetime_unlock`. Riverpod-exposed entitlement.
*Tests:* against a **`FakeInAppPurchase`** — available→restore grants; unavailable→cache
fallback; purchased/restored events grant + complete; not-owned stays ungated.

**#28 — Trial service + Auto Backup.** `SPEC.md` §6.2: `trialStart` on first launch (via
`Clock`), `daysLeft`/`expired` (28-day boundary). Enable Android Auto Backup
(`allowBackup=true` + rules covering shared_preferences).
*Tests (FakeClock):* `daysLeft` clamps at 0; `expired` flips at exactly 28 days; purchased
overrides expiry.

**#29 — Paywall overlay.** Blocking full-screen overlay mounted above the app when
`expired && !purchased` (`cs-paywall.jsx`); "Unlock · £4 once" → purchase flow; dismisses
permanently on entitlement; trial not reset by redo baseline.
*Tests:* widget — expired→overlay shown & blocks; purchased→absent; E2E paywall-after-expiry
(seed `trialStart` 28+ days back via FakeClock) + sandbox/license-tester purchase.

---

## M9 — Icon, store assets, release  *(needs everything)*

**#30 — App icon ("Alphabet") + assets.** The six shapes in a 2×3 grid on a squircle tile
(`DESIGN.md` §9); generate Android adaptive-icon resources (ink-on-white + monochrome) and
export sizes; decide whether the store tile may use a single brand colour (in-app stays mono).
*Tests:* manual visual check; icon resources present at all DPIs.

**#31 — Release pipeline + Play listing.** Verify `release.yml` → fastlane → Play internal
track end-to-end with the signing secrets; create the £4 managed product + license testers;
write the listing with the **trial-then-buy disclosure** (`SPEC.md` §6.4); first-run trial
disclosure.
*Tests:* a tagged build produces a signed AAB and uploads to the internal track (dry-run /
draft); first-run discloses the trial.
