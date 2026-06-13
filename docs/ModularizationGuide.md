# Modularization & Architecture Guide

> Our equivalent of *Now in Android*'s `ModularizationLearningJourney`. There is no
> single official "Now in Android of iOS"; this document is the canon we curate
> instead. Keep it short, opinionated, and current.

## 1. Why modularize

- **Build & preview speed** — touching one feature recompiles one module, not the app.
- **Parallel work** — clear interface boundaries let people work without stepping on each other.
- **Forced layering** — the dependency graph is acyclic, so responsibilities stay honest.
- **Reuse across 4 destinations** — iPhone/iPad/Mac/Watch share the same domain & design code.

## 2. The layer cake (dependencies point DOWN only)

```
        ┌─────────────────────────────────────────────┐
Apps    │  PetApp (iOS/iPad/Mac) · PetWatchApp · PetWidgets │   thin shells: entry + DI + root nav
        └───────────────┬─────────────────────────────┘
                        │
Features │   PetHome · Care · Store · Stats · Settings        each previewable in isolation
        └───────────────┬─────────────────────────────┘
                        │
UI       │   DesignSystem · PetRenderer                       Liquid Glass, shaders, character
        └───────────────┬─────────────────────────────┘
                        │
Core     │ PetKit (domain) · PetPersistence · PetSync · PetIntents · PetWidgetShared
        └───────────────────────────────────────────────┘
```

**Rules**
1. A module may depend only on modules **strictly below** it. Never sideways between
   features, never upward.
2. `PetKit` (the domain) depends on **nothing** in this project and imports **no UI**.
   It is plain Swift, testable with `swift test` alone.
3. Features talk to each other only via the app shell (routing) or shared Core types —
   never `import FeatureB` from `FeatureA`.
4. Cross-cutting types that two layers must agree on (e.g. `ActivityAttributes`,
   the `Pet` model) live in the **lowest** module that needs them (`PetWidgetShared`,
   `PetKit`) so both sides import down, not across.

## 3. Module responsibilities

| Module | Owns | Must NOT |
|---|---|---|
| `PetKit` | `Pet` model, state machine, hunger/energy/mood decay tick, pure game rules | import SwiftUI/UIKit/SwiftData |
| `PetPersistence` | SwiftData schema, `PetRepository` protocol + impl | leak SwiftData types past the protocol |
| `PetSync` | CloudKit mirroring, WatchConnectivity session | own the source of truth (that's the repository) |
| `PetIntents` | `AppIntent`s: Feed/Play/Pet/CheckStatus/ToggleSleep | contain UI; perform() must be fast |
| `PetWidgetShared` | `ActivityAttributes`, small shared widget views | depend on feature modules |
| `DesignSystem` | colors, type, Liquid Glass wrappers, Metal shaders, watch fallbacks, reusable components | know about the `Pet` domain specifics |
| `PetRenderer` | `PetRenderable` protocol; Rive impl (iOS/Mac) + Canvas impl (watch) | hardcode gameplay rules |
| `Features/*` | one screen/domain each, its own `@Observable` view-model-ish model | own persistence/sync directly (inject it) |

## 4. State & concurrency conventions

- **MV pattern.** A feature exposes one `@Observable` model held by the view via
  `@State`; share down-tree via `@Environment`; two-way bind with `@Bindable`.
  No `ObservableObject`/`@Published`. No ViewModels-for-the-sake-of-it.
- **Default `@MainActor` isolation** is ON (Swift 6.2 approachable concurrency). Assume
  code is main-actor unless you say otherwise. Push the simulation tick, shader/image
  work, and batch persistence off-main with `@concurrent` or a dedicated `actor`.
- **Dependency injection** via SwiftUI `Environment`. Escalate to `swift-dependencies`
  only when you need test seams the Environment can't give you cleanly.
- **Persistence is always behind `PetRepository`.** Views/features never touch SwiftData
  or CloudKit directly, so the engine stays swappable (SwiftData → SQLiteData if needed).

## 5. Platform constraints (non-negotiable)

- **watchOS has no Metal** → no SwiftUI shaders, no RealityKit, no Rive. `PetRenderer`
  ships a `CanvasPetRenderer` for watch and a `RivePetRenderer` for iOS/Mac, chosen
  behind the `PetRenderable` protocol. Author both from one art source.
- **Liquid Glass = chrome only.** `.glassEffect()` on toolbars/HUD/controls, never over
  the pet or primary content (Apple HIG + legibility).
- **Respect accessibility.** Honor Reduce Transparency / Increase Contrast / Reduce
  Motion — the signature look must degrade gracefully, not break.
- **Quality tiers.** Gate shader complexity & particle counts on device class and
  `ProcessInfo.processInfo.thermalState`; fall back to a calmer pet under thermal/low-power.

## 6. Versioning strategy

- Build with **stable Xcode 26.5 / Swift 6.3.2**. Do not pin shipping builds to Xcode 27
  betas.
- Deployment floor: **iOS/iPadOS 26, macOS 26, watchOS 26.**
- Anything iOS 27-only (landscape Dynamic Island, reorderable-on-watch, `.small`
  Live Activity family, 2nd-gen Liquid Glass) goes behind `if #available(iOS 27, *)`
  with a 26 fallback. Re-evaluate the floor when iOS 27 ships (fall 2026).

## 7. Adding a new feature (checklist)

1. `Modules/Features/<Name>/` with `Sources/`, `Tests/`, and a `Preview`/Example target.
2. Define its `@Observable` model in the feature; inject `PetRepository` via Environment.
3. Reusable visuals → `DesignSystem`, not the feature.
4. New user action that should also work from Siri/widget/Control Center → add an
   `AppIntent` in `PetIntents`, then call it from the UI (one definition, many surfaces).
5. Unit-test the model with **Swift Testing**; snapshot only *static* layouts.
6. Wire it into the app shell's navigation — features don't import each other.
