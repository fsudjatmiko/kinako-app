# Git Workflow, Commit Standards & PR Protocol

## 1. Branch Strategy

All development work follows an isolated feature-branch workflow branched from `main`.

### Branch Naming Conventions
Format: `<type>/<issue-or-ticket-id>-<short-description>` or `<type>/<short-description>`

* `feat/` — New user-facing capabilities or UI components (e.g., `feat/offline-currency-engine`, `feat/ghost-split-tray`)
* `fix/` — Bug fixes or UI rendering corrections (e.g., `fix/chamfer-stroke-clipping`, `fix/zero-day-pacing-division`)
* `refactor/` — Code adjustments without behavior changes (e.g., `refactor/swiftdata-model-actors`)
* `perf/` — Rendering optimizations or query performance improvements (e.g., `perf/metal-shader-timeline`)
* `test/` — Adding or refining unit/UI test suites (e.g., `test/pacing-engine-edge-cases`)
* `chore/` — Build system, CI, Xcode project settings, or documentation updates (e.g., `chore/bundle-rates-seed-json`)

---

## 2. Commit Message Standards (Conventional Commits)

Kinako strictly follows the **Conventional Commits** specification. Commit messages must be atomic, structured, and informative.

### Format
```text
<type>(<scope>): <subject in imperative, present tense>

[optional body explaining WHY the change was made, trade-offs, and context]

[optional footer referencing issues or breaking changes]


Approved Scopes

models, currency, pacing, ghost-split, regret-audit, design-system, numpad, testing, ci, deps

Examples

⚬ Good: feat(currency): implement offline lookup fallback in ExchangeRateService
⚬ Good: fix(pacing): prevent divide-by-zero when days remaining in month is zero
⚬ Good: style(design-system): tune Sandalphon chamfer stroke gradient stops
⚬ Bad: fixed stuff
⚬ Bad: updated swiftdata

3. Pull Request (PR) Protocol

Prerequisites Before Opening a PR

1. Zero Compiler Warnings: Swift 6 strict concurrency checks must report zero warnings or data-race violations.
2. Green Test Suite: All unit tests in KinakoAppTests must pass locally.
3. Hig Compliance Check: Verify that native sheets, toolbars, and dynamic type render properly without broken layout constraints.
4. CloudKit Compatibility Check: Confirm that no @Attribute(.unique) was introduced and all stored properties have default values.

4. Pull Request Template

Copy and paste this template into .github/PULL_REQUEST_TEMPLATE.md or directly into the PR description:

## Description
<!-- Provide a high-level summary of the purpose and user/system impact of this PR. -->

## Changes Made
- [ ]

## Scope & Area
- [ ] SwiftData Models / CloudKit Schema
- [ ] Currency Conversion Engine
- [ ] UI / Design System (`SandalphonChamfer`, Tohka theme tokens)
- [ ] Unique Features (Pacing / Ghost Split / Time-Cost / Regret Audit)
- [ ] Testing / QA

## Verification Steps
<!-- Step-by-step instructions on how a reviewer can verify this change locally. -->
1. Open the app or run test suite `...`.
2. Navigate to `...`.
3. Verify that `...`.

## Automated Test Coverage
- [ ] Added unit tests covering new business logic (`@Test` / `#expect`)
- [ ] Existing test suites pass with zero regressions
- [ ] In-memory container used for SwiftData tests (no disk/iCloud dependency)

## Checklist
- [ ] Swift 6 strict concurrency compiles with zero warnings
- [ ] CloudKit compatibility rules upheld (no `@Attribute(.unique)`, default values present)
- [ ] Standard Apple HIG navigation and functional copy maintained



---

### Project Setup Complete

Your modular Antigravity documentation suite is now fully assembled:
* **Root:** `AGENTS.md`
* **Data & CloudKit:** `.agents/rules/architecture.md`
* **UI & Tohka Theme:** `.agents/rules/design_system.md`
* **Mechanics & Logic:** `.agents/rules/features_spec.md`
* **Testing & QA:** `.agents/rules/testing_qa.md`
* **Git & PRs:** `.agents/rules/git_workflow.md`
