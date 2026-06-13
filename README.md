# 🐾 VirtualPet

A pure–Apple-ecosystem virtual pet for **iPhone · iPad · Mac · Apple Watch**, built
visuals-first with the newest Apple technologies (Liquid Glass, SwiftUI Metal
shaders, Live Activities / Dynamic Island, App Intents, Rive-driven character).

> **Status:** project scaffold / foundation (内功). The architecture, modules,
> tooling, and CI are in place; gameplay & art are built on top of this.

---

## Tech stack (locked after research, 2026-06)

| Concern | Choice | Notes |
|---|---|---|
| Language / toolchain | **Swift 6.3.2 / Xcode 26.5** (stable) | Xcode 27 / Swift 6.4 are still betas → not used for shipping builds |
| Deployment floor | **iOS/iPadOS 26 · macOS 26 (Tahoe) · watchOS 26** | iOS 27-only APIs gated behind `if #available`; bump floor at the 27 GA (fall 2026) |
| UI | SwiftUI, **MV pattern** (`@Observable` + `@State`/`@Environment`) | No MVVM ceremony, no TCA unless state logic demands it |
| Concurrency | Swift 6 strict + **default `@MainActor` isolation** (approachable concurrency) | Heavy work explicitly `@concurrent` / off-main |
| Persistence | **SwiftData** behind a repository protocol | Model kept CloudKit-compatible (all-optional, no unique constraints) |
| Sync | **CloudKit** (phone/iPad/Mac source of truth) + **WatchConnectivity** (real-time watch) | Watch treated as a thin client (SwiftData+CloudKit on watchOS is unreliable) |
| Character | **Rive** state machine (iPhone/Mac) | Watch gets a separate Canvas/TimelineView tier — Metal/RealityKit/Rive don't exist on watchOS |
| "Living pet" surfaces | **App Intents**-first → widgets, Control Center, Live Activity / Dynamic Island, Siri, Spotlight, complications | One intent vocabulary, many surfaces |
| Project generation | **Tuist 4.200.x** | `.xcodeproj`/`.xcworkspace` are generated & git-ignored |
| Format / lint | **swift-format** (toolchain) + **SwiftLint 0.63.3** | Formatter auto-fixes, linter blocks |
| Tests | **Swift Testing** (unit) + XCTest (UI/perf via XCUITest, XCTHitchMetric) | + swift-snapshot-testing for static UI |
| CI | GitHub Actions (`macos-26`, Xcode 26.5 pinned) + Fastlane | Xcode Cloud / self-hosted runner for device + release |

See [`docs/ModularizationGuide.md`](docs/ModularizationGuide.md) for the architecture
covenant (module layering, dependency rules, platform constraints).

---

## Getting started

```bash
# 1. Provision the pinned toolchain (Tuist, SwiftLint). One-time per machine.
brew install mise            # if you don't have it
mise install                 # reads mise.toml

# 2. Enable git hooks (format + lint on commit). One-time per clone.
brew install pre-commit      # if you don't have it
pre-commit install

# 3. Resolve dependencies and generate the Xcode project.
mise exec -- tuist install   # resolves SPM deps (Rive, ...)
mise exec -- tuist generate  # creates VirtualPet.xcworkspace (git-ignored)

# 4. Open & run.
open VirtualPet.xcworkspace
```

> Tip: if you `mise activate` in your shell, you can drop the `mise exec --` prefix
> and just run `tuist generate`, `swiftlint`, etc.

### Everyday commands

```bash
mise exec -- tuist generate          # regenerate after editing Project.swift / adding files
swift format --in-place --recursive Sources Modules   # format
swiftlint lint --strict              # lint
mise exec -- tuist build             # build via Tuist
mise exec -- tuist test              # run the test plan
```

---

## Repository layout

```
VirtualPet/
├── Tuist/                       # Tuist config + ProjectDescriptionHelpers (DRY target factories)
├── Project.swift                # the project + target graph (apps, extensions, modules)
├── Tuist.swift                  # workspace/install config
├── Modules/                     # all real code — layered, acyclic SPM-style modules
│   ├── PetKit/                  # ⚙️  domain: Pet model + state machine + decay tick (no UI)
│   ├── PetPersistence/          # 💾  SwiftData + repository protocol
│   ├── PetSync/                 # ☁️  CloudKit + WatchConnectivity
│   ├── PetIntents/              # 🎙️  App Intents vocabulary (feed/play/status/sleep)
│   ├── PetWidgetShared/         # 📲  ActivityAttributes + shared widget views
│   ├── DesignSystem/            # 🎨  Liquid Glass wrappers + Metal shaders + watch fallbacks
│   ├── PetRenderer/             # 🐾  character rendering: Rive (iOS/Mac) + Canvas (watch)
│   └── Features/                # 🧩  PetHome, Care, Store, Stats, Settings (each previewable)
├── Apps/
│   ├── PetApp/                  # iPhone + iPad + Mac (native SwiftUI multiplatform target)
│   ├── PetWatchApp/             # watchOS (separate target — watchOS can't join multiplatform)
│   └── PetWidgets/              # WidgetKit extension: widgets + Live Activity / Dynamic Island
├── docs/                        # ModularizationGuide.md + decision records
├── fastlane/                    # build / test / beta lanes
└── .github/workflows/           # CI
```

---

## Platform reality check (read before adding visuals)

- **Apple Watch has no Metal.** SwiftUI shaders (`colorEffect`/`layerEffect`/
  `distortionEffect`), RealityKit, and Rive **do not run on watchOS** and never will.
  The watch pet is a *separately authored* tier using `Canvas` + `TimelineView` +
  SF Symbols animation. Plan two character pipelines from the same art source.
- **Liquid Glass is for chrome, not content.** Use `.glassEffect()` /
  `GlassEffectContainer` on HUD/controls — never layered over the pet itself.
- **Gate the bleeding edge.** Landscape Dynamic Island, reorderable-on-watch, the
  `.small` Live Activity family, and the 2nd-gen Liquid Glass refinements are
  **iOS 27-only** — wrap them in `if #available(iOS 27, *)`.
