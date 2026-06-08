# CogScroll — Design & Engineering Doc

A minimalist brain-training app. Nine cognitively-validated games, pure black &
white, calm and abstract. This doc is the source of truth for the design system
and the codebase so a new contributor can extend it without re-deriving decisions.

Product spec: `uploads/brain-training-app-spec.md`.

---

## 1. What exists today

`CogScroll.html` is the working app. Everything is on-device, no account, no
backend. Built and verified:

- **Nine games** (see §6), grouped by domain in the catalog.
- **Top-level "Today" set** — an adaptive daily session of 4–5 games that
  weights weak domains; runs back-to-back, leads the home screen (§7.3).
- **Onboarding baseline** — first-run, one short game per domain, seeds all six
  domain scores, then reveals the radar (§7.1).
- **Progress dashboard** — six-spoke radar + baseline ghost + per-domain
  sparkline & trend. Lives behind **Settings → Progress** (§7.2).
- **Settings** — progress, daily reminder (toggle + time), membership/trial,
  redo baseline (wipes analytics, confirmed), export/import JSON (§7.4).
- **Trial-end paywall** — after a 28-day trial, a blocking one-time-purchase
  screen (§7.5).

Shared analytics layer (`cs-data.jsx`): `cogscroll:domains` store +
`CS.recordResult(domain, score)` fed by every game; normalization to 0–100
against the spec's good/avg/poor bands; trend + trial helpers.

**Files:** `cs-core` (kit) → `cs-data` (analytics) → `cs-radar` → game modules
→ `cs-onboarding` → `cs-session` → `cs-dashboard` → `cs-settings` → `cs-paywall`
→ `cs-home` → `cs-app`. Load order matters (see §8).

---

## 2. Design language

The visual direction was chosen by exploring a design space (palette, type,
shape, layout, feedback) and locking one option per axis, then deliberately
re-cast to **pure black & white** with **motion-led feedback**.

- **Palette — pure mono.** White `#FFFFFF` ground, near-black `#111111` ink.
  No accent colour anywhere. This is a deliberate constraint and is also
  colour-blind-safe: correctness is never carried by hue.
- **Type — Space Grotesk** (Google). One family. Big tabular numerals for
  metrics/counters; tracked uppercase micro-labels (`letter-spacing: 0.22em`)
  for chrome.
- **Form — flat geometry.** Six abstract shapes (circle, square, triangle,
  diamond, cross, hexagon). No icons-as-illustration, no skeuomorphism.
- **Tone — calm, quiet, puzzle-like.** Generous whitespace, the stimulus is the
  hero, minimal chrome, wide tap targets.

### Tokens (`cs-core.jsx`, object `T`)
| token | value | use |
|---|---|---|
| `bg` | `#FFFFFF` | surface |
| `fg` | `#111111` | ink / shapes / fills |
| `sub` | `rgba(17,17,17,0.42)` | secondary text |
| `faint` | `rgba(17,17,17,0.2)` | hints, disabled |
| `line` | `rgba(17,17,17,0.14)` | hairlines, idle cells |
| `panel` | `#F4F4F4` | inset wells (icons, keypad, idle grid cells) |
| `font` | `'Space Grotesk', sans-serif` | everything |

The app screen is a fixed **390 × 844** frame, centered and scaled to fit any
viewport by `Stage` (in `cs-app.jsx`), on a `#E4E4E4` backdrop with a soft shadow.

---

## 3. Motion-led feedback (the heart of the system)

Feedback is communicated by **motion of the object itself**, not colour and not a
generic badge. Success motion *conforms to the thing you interacted with*.

| Motion | When | Looks like | Component |
|---|---|---|---|
| **Ring bloom** | correct, round stimulus | concentric circle outlines expand + fade | `<Bloom radius="50%">` |
| **Double pulse** | correct, square/cell stimulus | two rounded-square outlines emanate, staggered | `<Pulse radius={n}>` |
| **Directional surge** | correct, Flanker | the arrow row drives in the answer direction and fades | CSS `.cs-surge-r` / `.cs-surge-l` |
| **Shake** | any wrong answer | the stimulus becomes an outline and jitters L-R | CSS `csShake` (class `.cs-shake` or inline `animation`) |
| **Pop / bounce** | stimulus entrance | quick scale-in | CSS `csPop` / `csPopBig` |

Rules of thumb:
- **Round object → ring; square object → square pulse; directional task → directional surge.** N-Back and Reaction Time keep the ring (round stimuli).
- **The stimulus must stay visible for the entire feedback motion**, then blank
  only *between* trials. (A past bug hid the shape before its motion finished —
  don't reintroduce it.)
- **Correct rejections stay quiet** where withholding is the correct action — but
  Go/No-Go's correct withhold still gets a (square) success motion so it never
  feels like nothing happened.
- Keyframes live in `CogScroll.html`'s `<style>`: `csPop, csPopBig, csRing,
  csRing2, csPulse, csShake, csSurgeR/L, csGhostA/B, csFade, csDeplete`.

> ⚠️ Inline `style={{animation:'none'}}` overrides the `.cs-shake` class. If an
> element needs both a one-shot entrance and a later shake, drive **both** via
> inline `animation` (see Go/No-Go), don't mix inline `none` with the class.

---

## 4. Shared UI kit (`cs-core.jsx`, exported on `window.CS`)

- `Shape({id, size, color, outline})` — the six stimuli. `id` 0–5 =
  circle, square, triangle, diamond, cross, hexagon. `SHAPE_NAMES` matches.
- `Bloom`, `Pulse` — success motions (self-centering on nearest positioned ancestor).
- `TopBar({onBack, title, right})` — back chevron + game name + right slot (level/counter).
- `WideButton({label, onClick, variant, icon})` — full-width pill (`solid`/`hollow`, optional `check`/`cross` icon). Wide by design — big tap target, no wasted space.
- `Progress({idx, total})` — numeric `08 / 20` + depleting track. For trial counting.
- `Countdown({ms, k})` — depleting line for response-window games. Key it by trial
  (`k={idx}`) so it restarts; only render while the stimulus is actually shown.
- `Intro({children, footnote, legend, onStart, startLabel})` — the calm start screen.
- `RoundEnd({value, caption, sub, delta, levelMsg, onContinue, continueLabel})` —
  generic results screen. `delta = {dir:'up'|'down', text}` ('up' always means
  "better", regardless of whether the metric is higher- or lower-is-better).
- `Label`, `Check`, `Cross` — primitives.
- `store.get/set(key, default)` — namespaced `localStorage` (`cogscroll:<key>`).
- `register(game)` / `games[]` — the registry (see §5).
- `Radar({scores, size, reveal, ghost})` — pure-SVG six-spoke radar
  (`cs-radar.jsx`). `scores`/`ghost` are `{domain: 0–100 | null}`; `ghost`
  draws a faint dashed baseline polygon behind the current one.

### Analytics layer (`cs-data.jsx`, on `window.CS`)
- `DOMAINS` (radar order) / `DOMAIN_SHORT` (two-line labels).
- `normalize(key, raw)` — raw metric → 0–100 vs population norms. Lower-is-better
  metrics (ms, seconds) invert here, so 'up' always means better downstream.
  n-back takes `{acc, n}`; everything else a number.
- `recordResult(domain, score)` — appends to history + updates an EMA score
  (`old*0.6 + new*0.4`). **Every game calls this in `finish()`.**
- `domainScores()` / `baselineScores()` / `domainHistory(d)` / `domainTrend(d)`
  (`{state:'improving'|'stable'|'declining'|'none', delta, history}`; needs ≥3
  results) / `hasData()`.
- `trialInfo()` (`{daysLeft, expired, purchased,…}`) / `purchase()` / `TRIAL_DAYS`.
- `exportData()` / `importData(text)` / `clearAnalytics()` (wipes PERF_KEYS only
  — not trial/purchase/reminder prefs).

---

## 5. Architecture

Plain React 18 + Babel-in-browser (pinned in `CogScroll.html`). Each file is a
`<script type="text/babel">`. No build step. Files share state through the global
`window.CS` namespace (set up in `cs-core.jsx`, which loads first).

**Load order (in `CogScroll.html`):** core → game modules → home → app.

**Game registry.** Each game module calls `CS.register({ id, name, domain, Icon, Component })`.
`Component` receives `{ onExit }`. `Icon` is a tiny inline-SVG glyph.

**Router.** `cs-app.jsx` renders `<Stage>` wrapping the current screen. `route`
is either a game `id` or a special string: `'baseline'` (`CS.Baseline`),
`'session'` (`CS.Session`), `'dashboard'` (`CS.Dashboard`), `'settings'`
(`CS.Settings`), or `null` (`CS.Home`). Home (`cs-home.jsx`) leads with the
Today set, then lists `CS.games` grouped by `domain` via `DOMAIN_ORDER`. The
**paywall** (`CS.Paywall`) renders as an absolute overlay inside the Stage frame
whenever `CS.trialInfo().expired && !purchased`, blocking everything beneath.

**Runner `baseline` prop (shared by onboarding + Today session).** Games take an
optional second prop `baseline`. When present a game: hides its own `TopBar`
(the runner draws a unified header), runs `baseline.trials`/`baseline.points`
trials if given (else full length), and on `finish()` calls
`baseline.onDone(normalizedScore)` **instead of** showing `RoundEnd`. The
runner's Skip calls `baseline.onSkip()`. `recordResult` fires either way, so
both the baseline and daily sessions feed the dashboard. Engine reads `baseline`
via a `blRef` (never the stale first-render closure).

**Per-game pattern (important — every game follows this).**
A game is a component holding `ui` state (`useState`) plus a mutable **engine**
object created once in a `useRef`. The engine owns the loop: timers, current
trial, results, the staircase. It talks to React via a captured `up(patch)` =
`setUi(s => ({...s, ...patch}))`. Common methods: `clear()` (cancels timers),
`start()`, `trial()`, `tap()/pick()/respond()`, `resolve()`, `advance()`,
`finish()`. `useEffect(() => () => engine.clear(), [])` cancels timers on unmount.

> Engine methods that need *current* React state must read it via a ref
> (`uiRef.current`), never the `ui` closure captured at engine-creation (first
> render) — that value is stale forever. (A past Flanker bug: `if (ui.stim)`
> read the stale first-render value and silently dropped every tap.)

**Phases.** Games move through `intro → playing → round` (some add `show`/`recall`
sub-stages). `intro` uses `CS.Intro`; `round` uses `CS.RoundEnd`.

---

## 6. The nine games

Files: `cs-nback.jsx`, `cs-memory.jsx` (Digit Span, Spatial Grid),
`cs-attention.jsx` (Stroop, Flanker, Go/No-Go), `cs-flex.jsx` (Task Switching,
Trail Making), `cs-speed.jsx` (Reaction Time).

| Game | Domain | Mechanic | Metric | Adaptation |
|---|---|---|---|---|
| **N-Back** | Working Memory | tap when shape repeats N back | accuracy % | N up >85% / down <60% (cap 4) |
| **Digit Span** | Working Memory | recall digits on a keypad, in order | best span | ±1 length on 2 correct / 2 fails |
| **Spatial Grid** | Spatial Reasoning | repeat the flashed 4×4 cell sequence | best span | ±1 length staircase |
| **Stroop** | Attention & Inhibition | tap the shape you SEE, not the word on it | accuracy % | per-round |
| **Flanker** | Sustained Attention | tap the way the MIDDLE arrow points | accuracy % | per-round |
| **Go / No-Go** | Attention & Inhibition | tap circle (Go), withhold square (No-Go) | accuracy % | per-round |
| **Task Switching** | Mental Flexibility | judge SHAPE or FILL — rule keeps switching | accuracy % | per-round |
| **Trail Making** | Mental Flexibility | connect 1→12 in order, against the clock | seconds | per-round |
| **Reaction Time** | Processing Speed | tap the instant the shape appears | avg ms / best | baseline measure |

Persistence keys (`cogscroll:*`): `nback-n`, `nback-acc`, `digit-span`,
`corsi-span`, `stroop-acc`, `flanker-acc`, `gng-acc`, `switch-acc`, `trail-time`,
`rt-avg`. **Every game also calls `CS.recordResult(domain, CS.normalize(key, raw))`
in `finish()`** to feed the analytics layer. The six baseline/session games
(reaction, flanker, gonogo, nback, corsi, trails) additionally support the
`baseline` prop (§5); the other three only record results.

App-level keys: `domains` (analytics store), `onboarded`, `baselinePrompted`,
`session` (`{date, steps, done}`), `notify`, `notifyTime` (`{h, m}`),
`trialStart`, `purchased`.

### Two B&W adaptations (validate with stakeholders)
The spec's Stroop and Task Switching rely on colour, which our mono system rules
out. Both were re-cast to preserve the *cognitive construct* without colour:
- **Stroop → shape-Stroop.** A word naming one shape is drawn over a *different*
  shape (word on a white plate so it's always legible); tap the shape you see.
  Same read-vs-perceive interference.
- **Task Switching → shape/fill.** The two switching rules are "judge the shape
  (circle/square)" vs "judge the fill (filled/hollow)". Same set-shifting / switch cost.

---

## 7. Adaptive & progress features (built)

All three are live, built on the analytics layer (§4). Pure B&W, `CS` kit,
registry. Personal trajectory only — no scores vs other users.

### 7.1 Onboarding baseline (`cs-onboarding.jsx` → `CS.Baseline`)
First-run, surfaced as a locked "Today" hero (or **Settings → Start baseline**).
**One gentle game per domain** (`BASELINE_SET`: reaction, flanker, gonogo,
nback, corsi, trails), abbreviated to land under ~5 min. Welcome → games
auto-advance (each keeps its own Intro; unified header with progress + **Skip**)
→ completion **reveals the seeded radar**, then lands on Home. Skipped domains
stay "no data". No mid-flow resume (restarts clean). Sets `onboarded` +
`baselinePrompted`.

### 7.2 Progress dashboard (`cs-dashboard.jsx` → `CS.Dashboard`)
Reached from **Settings → Progress** (deliberately off the main screen).
`CS.Radar` with a dashed **baseline ghost** + legend, then a per-domain row:
sparkline (auto-scaled, min 20-pt span) + trend mark (▲ Improving / — Stable /
▼ Declining via `domainTrend`, recent‑vs‑earlier; "Not enough data yet" under 3
results) + the 0–100 score.

### 7.3 Adaptive Today set (`cs-session.jsx` → `CS.Session`)
Top-level hero on Home (compact icon row + chevron, focus-dot on weak picks).
`pick()` chooses **4–5 distinct domains** by weight (×3 bottom of range, ×2
below average, ×1 maintenance; unmeasured ×2), then a random game per domain
(so no game repeats). Persisted per calendar day in `session` (regenerates only
when the date changes). The guided runner plays full-length rounds back-to-back
(reusing the `baseline` prop, §5), marks each done, supports Continue/▢ Done
states, and ends on a short session-complete screen. Pre-baseline the hero is
locked and points to the baseline.

### 7.4 Settings (`cs-settings.jsx` → `CS.Settings`)
Progress link · **Reminders** (on/off toggle + custom mono time spinner →
`notify`/`notifyTime`; preference only, no real push) · **Membership** (trial
days left / Unlock, or Lifetime access) · **Assessment** (start/redo baseline;
redo confirms then `clearAnalytics()`) · **Backup** (export/import JSON).

### 7.5 Trial paywall (`cs-paywall.jsx` → `CS.Paywall`)
After `TRIAL_DAYS` (28) a blocking full-frame overlay (mounted by `App` over the
Stage) gates the app: one-time £4 purchase via Google Play. `onUnlock` →
`CS.purchase()` (sets `purchased`) and dismisses permanently. Trial isn't reset
by a baseline redo.

Domains: Working Memory, Processing Speed, Attention & Inhibition, Mental
Flexibility, Spatial Reasoning, Sustained Attention.

---

## 8. Conventions / gotchas
- Pure HTML/CSS/React, no build, pinned CDN script tags with integrity hashes —
  keep them exactly as-is when adding files.
- **Load order** (in `CogScroll.html`): `cs-core` → `cs-data` → `cs-radar` → the
  five game modules → `cs-onboarding` → `cs-session` → `cs-dashboard` →
  `cs-settings` → `cs-paywall` → `cs-home` → `cs-app`. `cs-data` must precede any
  `finish()` (which calls `recordResult`); add new modules before `cs-app.jsx`.
- Don't introduce colour. Don't add a second font. Keep tap targets ≥ ~44px.
- When adding a game, wire `CS.recordResult(domain, CS.normalize(key, raw))` into
  its `finish()`, and — if it should appear in baseline/session — support the
  `baseline` prop (§5) via a `blRef`. Add a `normalize` case in `cs-data.jsx`.
- Animations are brief; static screenshots (html-to-image) often miss them —
  **animated/absolute overlays (Welcome, Complete, Paywall, dark cards) frequently
  capture blank**. Verify via the live DOM (`eval_js`: text content, computed
  opacity/zIndex), not the screenshot.
- Keep each game's engine in its module; share only through `window.CS`.

---

## 9. App icon

**Chosen direction: "Alphabet"** — the six stimulus shapes (circle, square,
triangle, diamond, cross, hexagon) laid out in a 2×3 grid on a squircle tile.
It puts the product's entire visual vocabulary in one mark and is unmistakably
this app. Pure mono, flat geometry — same system as everything else.

- **Primary treatment:** ink shapes `#111111` on a white `#FFFFFF` tile;
  inverse (white shapes on `#111111`) is the dark/alt variant.
- Glyphs + a multi-size tile renderer live in `cs-icon-glyphs.jsx`; all six
  explored directions are presented on the canvas in `CogScroll Icons.html`
  (Bloom, Hex, Radar, Feed, Alphabet, Scroll).
- Corner radius ≈ 22.5% of tile size. Shapes sit in a generous safe area
  (~26px margin in the 100×100 box) so the grid stays legible down to ~20px.
- **Open:** whether the store tile may use a single brand colour (the in-app
  pure-mono rule would stay unchanged); final export sizes (1024 / 180 / 120 /
  favicon) not yet generated.
