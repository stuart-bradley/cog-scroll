# CogScroll

A minimalist brain-training app. Nine cognitively-validated games across six cognitive
domains, in pure black & white with motion-led feedback. Fully on-device — no account,
no backend, no network. Free for 28 days, then a one-time purchase to keep using it.

> **Status: spec stage.** This repo currently holds the **design reference** and the
> **build spec**. The Flutter app is not built yet. See [`docs/SPEC.md`](docs/SPEC.md)
> for the full plan and [`docs/GITHUB_ISSUES.md`](docs/GITHUB_ISSUES.md) for the milestone
> breakdown.

## What it is

- **Nine games**, six domains — Working Memory, Processing Speed, Attention & Inhibition,
  Mental Flexibility, Spatial Reasoning, Sustained Attention.
- **Onboarding baseline** — one short game per domain seeds your six starting scores.
- **Adaptive "Today" set** — 4–5 games per day, weighted toward your weaker domains.
- **Progress dashboard** — a six-spoke radar (current vs your baseline) plus per-domain
  trend.
- **Pure mono, motion-led** — white ground, near-black ink, no colour anywhere; correctness
  is shown by motion, never hue (colour-blind-safe). Space Grotesk throughout.
- **Local-first** — analytics live on the device; export/import as JSON.

## Monetization

Free to install. A **28-day trial** of the full app, then a blocking one-time **£4** unlock
(no subscription, no ads). The purchase is restored automatically on reinstall / new device
via Google Play. See [`docs/SPEC.md` §6](docs/SPEC.md) for the trial + billing design.

## Repository layout

| Path | What |
|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | The build spec — requirements, architecture, data models, monetization, testing. |
| [`docs/GITHUB_ISSUES.md`](docs/GITHUB_ISSUES.md) | Milestone (M0–M9) and issue breakdown for implementation. |
| [`docs/design/`](docs/design/) | The original working **React/HTML prototype** + `DESIGN.md`, the visual & engineering source of truth. Open `docs/design/CogScroll.html` in a browser to play the reference. |
| `.claude/CLAUDE.md` | Project instructions for Claude Code during build sessions. |

## Tech (planned)

Flutter (Android-first), Riverpod, Drift, go_router, `in_app_purchase`,
`flutter_local_notifications`, `very_good_analysis`, patrol (E2E). Structure and CI/CD are
modelled on the [Tasks on Time](https://github.com/stuart-bradley/tasks-on-time) app.

## Building (future)

Not buildable yet — the spec drives the build. Once scaffolded (milestone **M0**), the
standard loop will be:

```sh
just setup   # flutter pub get + code generation
just check   # codegen + analyze + format-check + test
flutter run  # on a connected device / emulator
```

## License

TBD.
