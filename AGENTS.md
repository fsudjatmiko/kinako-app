# AGENTS.md — Kinako (iOS 26 / SwiftUI)

## Project Overview
- **App Name:** Kinako
- **Bundle Identifier:** `com.fsudjatmiko.KinakoApp`
- **Minimum Target:** iOS 26.0+ (macOS 17.0+ companion compatible)
- **Primary Tech Stack:** Swift 6 (Strict Concurrency), SwiftUI, SwiftData with CloudKit mirroring, Swift Testing / XCTest.
- **Design Core:** Apple Human Interface Guidelines (HIG) fused with an Anime GFX aesthetic inspired by Yatogami Tohka (*Date A Live*): midnight violet canvas, neon lavender/electric magenta energy borders, and custom chamfered geometry (*SandalphonChamfer*).

---

## Modular Reference Files
To maintain strict context isolation, refer to these specialized documents before implementing changes:
- **`@.agents/rules/architecture.md`** — SwiftData schema, CloudKit requirements, and offline-first currency conversion actor.
- **`@.agents/rules/design_system.md`** — Tohka color tokens, HIG typography mappings, chamfer shapes, haptics, and animation springs.
- **`@.agents/rules/features_spec.md`** — Specifications for Dynamic Buffer Pacing, Split Outing, Time-Cost Equivalency, and Regret Audit.
- **`@.agents/rules/testing_qa.md`** — XCTest & Swift Testing conventions, SwiftData in-memory test harnesses, and UI test flows.
- **`@.agents/rules/git_workflow.md`** — Git branching conventions, Conventional Commits, and PR checklist templates.

---

## Strict Engineering Invariants

### 1. Apple HIG & Navigation Protocol
- Use native `NavigationStack`, `TabView`, `.sheet`, and `.toolbar` items.
- Never build custom non-standard navigation wrappers or unconventional gesture frameworks.
- Functional button labels must use clear, standard language (`Save`, `Cancel`, `Add Expense`, `Done`). Do not use anime fantasy jargon on core controls.

### 2. CloudKit-Compatible SwiftData Rules
- **No `@Attribute(.unique)`**: CloudKit does not support atomic cross-device unique attributes.
- **Mandatory Default Values**: Every stored property in a `@Model` must have a default value or be optional (`?`).
- **Optional Relationships**: Any inter-model relationship must be marked optional.
- **Delete Rules**: Only `.nullify` and `.cascade` are permitted (never `.deny`).

### 3. Currency Immutability & Offline-First Core
- All expense entries freeze their conversion rate and base currency equivalent at the exact moment of creation. Never re-calculate historical records against live rates.
- The app must function 100% offline using bundled local rate seeds (`rates_seed.json`). Network updates occur silently in background tasks.

### 4. Concurrency & Safety
- Swift 6 strict concurrency checks enabled.
- Data operations outside the UI layer must run on isolated actors (e.g., `actor ExchangeRateService`).
- Views interact with SwiftData via `@Query` and `@Environment(\.modelContext)`. Background imports must use a dedicated `ModelActor`.

---

## Agent Task Execution Checklist
When prompted to build or modify features:
1. Verify compliance with CloudKit schema rules before altering models.
2. Read the corresponding `@.agents/rules/<file>.md` for specific domain guidance.
3. Provide accompanying unit tests using Swift Testing (`@Test`, `#expect`) or XCTest for all business logic, conversions, and models.
4. Keep git commits atomic and formatted according to `@.agents/rules/git_workflow.md`.
