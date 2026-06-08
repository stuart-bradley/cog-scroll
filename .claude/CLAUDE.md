# CLAUDE.md - Project Instructions for Claude Code

Project-specific guidance for Claude Code working on **CogScroll**. Update this file
whenever Claude does something incorrectly so it learns not to repeat the mistake.

## Project Overview

**CogScroll** is an **Android-first Flutter** brain-training app: nine cognitively-validated
games across six cognitive domains, in **pure black & white** with **motion-led feedback**.
It is **local-data-only** — no backend, no accounts, no cloud sync, no network for app
function. The one piece that touches a Google service is billing (the one-time unlock),
which is handled entirely by Google Play Billing — there is still no server of ours.

Business model: free install, **28-day trial**, then a blocking one-time **£4** purchase to
keep using the app (no subscription, no ads).

### Key docs (read before starting)

- `docs/SPEC.md` — the build spec: requirements, user stories, architecture, data models,
  monetization/trial design, testing strategy. **Source of truth for what to build.**
- `docs/GITHUB_ISSUES.md` — milestone (M0–M9) and issue breakdown.
- `docs/design/DESIGN.md` — the design-system + engineering doc for the original React
  prototype. **Source of truth for how it looks and behaves** (tokens, motion rules, the
  per-game mechanics, the two B&W adaptations).
- `docs/design/CogScroll.html` + `cs-*.jsx` — the working reference implementation. When a
  spec detail is ambiguous, the prototype's behaviour is the tie-breaker. Open the HTML in
  a browser to play it.

## Task Management

Work is tracked via **GitHub Issues** on this repository (see `docs/GITHUB_ISSUES.md` for
the seed set).

1. Pick the lowest-numbered open, unblocked issue.
2. Read it fully; read `docs/SPEC.md` and the relevant `docs/design/` reference first.
3. Create a feature branch: `git checkout -b feat/short-description`.
4. Reference the issue number in commits: `feat: n-back engine (#12)`.
5. Push the branch and open a PR (CI runs on PRs, not direct pushes to `main`). Use
   `Closes #N` in the body.
6. Work on one issue at a time. If you find out-of-scope work, file a new issue.

## Development Workflow

Verification loop for every change:

1. Make changes.
2. `just check` (codegen + analyze + format-check + test).
3. `dart format .` to auto-fix formatting.
4. Before opening a PR: `just check` again, green.

`just --list` shows all recipes (`codegen`, `analyze`, `test`, `format-check`, `e2e`, …).

## Flutter/Dart Conventions

### Code style

- Dart null safety required. Never `!`-force-unwrap without a comment explaining why it is
  safe.
- `dart format .` before committing; CI fails on unformatted code.
- Fix all `flutter analyze` warnings. Follow `very_good_analysis` (see `analysis_options.yaml`).
- **Do not use the `any` type without explicit approval.** Don't skip error handling.

### File structure (mirrors Tasks on Time)

```
lib/
  core/
    ui_kit/        # Shape painter, Intro, RoundEnd, WideButton, Progress, Countdown, radar
    theme/         # mono tokens, Space Grotesk text styles
    motion/        # AnimationController-driven feedback (bloom, pulse, surge, shake, pop)
    analytics/     # Drift DB + DAOs, recordResult / EMA / trend / baseline-ghost service
    scoring/       # pure normalize() functions (no Flutter imports)
    billing/       # in_app_purchase entitlement service
    time/          # Clock abstraction (inject — never call DateTime.now() directly)
    routing/       # go_router config
  features/
    games/<game>/  # one folder per game: pure engine + presentation widget
    baseline/      # onboarding runner
    session/       # adaptive "Today" runner
    dashboard/     # radar + per-domain trends
    settings/      # reminders, membership, redo baseline, export/import
    home/          # Today hero + catalog
    paywall/       # trial-end overlay
  main.dart
test/              # unit + widget tests (mirror lib/ layout)
integration_test/  # patrol E2E
```

Each feature uses `data/` + `domain/` + `presentation/` where it earns the split.

### State management

- **Riverpod only.** No `setState` outside trivial local widget state. No `GetX`, no `Provider`.
- Use `riverpod_generator` (`@riverpod`). Run `dart run build_runner build` after changing providers.
- DB-reading providers return `AsyncValue` and handle loading/error.

### Game engines

- Each game is a **pure Dart engine** (timers, trial loop, staircase, results) **separate
  from its widget** — no Flutter imports in the engine, so it is unit-testable. The widget
  drives the engine and renders phases `intro → playing → round`. This mirrors the
  prototype's engine/UI split (and avoids its stale-closure bug class by construction).
- Six games support the baseline/session **runner** (`reaction`, `flanker`, `gonogo`,
  `nback`, `corsi`, `trails`); the other three (`digitspan`, `stroop`, `taskswitch`) are
  **catalog-only**. Honour this split.

### Database

- All DB access via **Drift** DAOs. No raw SQL outside Drift table definitions.
- Drift holds **only** analytics that benefit from history/queries: `domain_scores`
  (EMA score per domain) and `score_history` (capped at 60 per domain). The **baseline
  ghost is derived** (`score_history.first` per domain) — there is **no** baseline column.
- Everything else (flags, per-game staircase params, display-only last-metrics, `trialStart`)
  is `shared_preferences`, mirroring the prototype's keys 1:1.
- Every schema change needs a migration (bump version + `MigrationStrategy`). Tests use
  in-memory `NativeDatabase.memory()`.

### Time & trial

- **Never call `DateTime.now()` directly.** Inject a `Clock` so trial expiry is
  deterministic in tests.
- Trial: `trialStart` set on first launch; `expired = elapsed ≥ 28 days && !purchased`.

### Billing

- Use `in_app_purchase`. **Google Play is the source of truth for entitlement** — on
  launch call `isAvailable()` → `restorePurchases()`; treat `purchasedCache` (a
  `shared_preferences` bool) only as the offline fallback when billing is unavailable.
- One **non-consumable** product. No backend / no server-side receipt verification (accepted
  for an indie app — see `docs/SPEC.md` §6).

### Navigation

- All routes in `lib/core/routing/`. Use `context.go()` / `context.push()` (go_router),
  never `Navigator.push` directly.

## Testing Requirements

Every change that adds or modifies behaviour **MUST** include tests, authored alongside the
change (TDD), never deferred to the end of a milestone.

- **Unit:** `normalize`, EMA, `domainTrend`, adaptive `pick()` weighting, trial math (with
  injected `Clock`), entitlement resolution (against a `FakeInAppPurchase`), each game
  engine, Drift DAOs (in-memory) incl. the 60-cap prune, export/import round-trip.
- **Widget:** each game's core interaction + feedback motion + `recordResult` wiring;
  paywall gating (expired→overlay, purchased→none); dashboard radar/sparkline/trend.
- **E2E (patrol):** baseline onboarding; daily session; export→import; paywall after expiry
  (seed `trialStart` via the injected clock); purchase via Play sandbox / license tester.

## Design Rules (non-negotiable — from `docs/design/DESIGN.md`)

- **No colour.** White `#FFFFFF` ground, ink `#111111`, panel `#F4F4F4`, plus the documented
  opacity tiers (`sub`, `faint`, `line`). Correctness is **never** carried by hue.
- **One font:** Space Grotesk (bundled as an asset). Tabular figures for metrics; tracked
  uppercase micro-labels for chrome.
- **Motion-led feedback:** round stimulus → ring bloom; square/cell → square pulse;
  directional task → directional surge; wrong → shake; entrance → pop. **The stimulus stays
  visible for the entire feedback motion** (a known prototype bug was hiding it early — don't
  reintroduce it).
- Tap targets ≥ ~44px. No Material You / dynamic colour (the app is fixed mono).
- Read `docs/design/DESIGN.md` before any UI change; keep the spec in sync if you change a
  component, token, screen, or motion.

## Build & CI

GitHub Actions (modelled on Tasks on Time):

- **CI** on every PR: `just check` (codegen + analyze + format-check + test).
- **E2E** on emulator (patrol).
- **Release** on git tags `v*.*.*`: `flutter build appbundle --release`, sign with keystore
  from GitHub Secrets, deploy to Play Store internal track via Fastlane.

Secrets: `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`,
`PLAY_STORE_JSON_KEY`.

### Flutter SDK path

Flutter is at `~/flutter/bin`. The `justfile` puts it on PATH; otherwise
`export PATH="$HOME/flutter/bin:$PATH"`.

## Identifiers (confirmed)

- applicationId: `com.stuartbradley.cogscroll` (permanent once on Play).
- IAP product id: `cogscroll_lifetime_unlock`; price **£4**.
- Display name: **CogScroll**.

## Things Claude Should NOT Do

- Don't add cloud/network/backend dependencies or user accounts — local-only by design.
- Don't introduce colour, a second font, or Material You.
- Don't call `DateTime.now()` directly — use the injected `Clock`.
- Don't store entitlement as authoritative local state — Google Play is the source of truth.
- Don't write iOS-only code; Android is the target (iOS is a possible later port).
- Don't use `BuildContext` across async gaps without checking `mounted`.
- Don't commit generated files (`.g.dart`, `.freezed.dart`) — gitignored, regenerated by
  `build_runner`.
- Don't use `GetX` or `Provider` — Riverpod only.
- Don't suppress lint warnings without an `// ignore:` comment explaining why.
- Don't commit without running tests first. Don't make breaking API changes without discussion.

## Commit Message Format

```
type(scope): description (#issue-number)

feat(games): n-back engine + accuracy normalization (#12)
fix(trial): clamp daysLeft at zero on clock skew (#31)
test(scoring): edge cases for reaction-time normalize (#9)
```

Types: `feat`, `fix`, `test`, `refactor`, `chore`, `docs`. **Do not co-author commits with
Claude / Anthropic.**

## Self-Improvement

After every correction or mistake, add a concise, actionable rule here so it isn't repeated.
Keep this file lean and accurate — consolidate duplicates, remove stale rules.
