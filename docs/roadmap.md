# VirtualPet Roadmap

Status of the build and what's next. `[x]` done · `[ ]` todo · `[~]` partial/stubbed.
See [`ModularizationGuide.md`](ModularizationGuide.md) for architecture rules.

---

## ✅ Done — foundation (内功)

- [x] Tuist modular project (13 targets), mise-pinned toolchain (Tuist/SwiftLint), swift-format, pre-commit, GitHub Actions CI, Fastlane skeleton
- [x] Domain core `PetKit` (stats / state machine / decay) + Swift Testing (7/7)
- [x] MV architecture (`@Observable`), Swift 6 strict + approachable concurrency
- [x] Rive pet on iOS/Mac (placeholder `Bear.riv`) + Canvas pet on watchOS; Metal aurora shader; Liquid Glass UI
- [x] SwiftData durable storage + App Group `SharedPetStore` (app↔widget↔intents bridge)
- [x] Live Activity / Dynamic Island; interactive Feed widget; App Intents (Feed/Play/Clean/ToggleSleep/CheckStatus) + Siri phrases
- [x] Builds green on iOS / iPadOS / macOS / watchOS + widget; runs on simulator and physical iPhone
- [x] Pushed to github.com/codeweiz/virtual-pet

---

## 🔜 Next — make it real (high priority)

### Art & character
- [ ] Replace `Modules/PetRendererRive/Resources/pet.riv` with a custom pet designed in the Rive editor; expose state-machine inputs `isAsleep` (bool), `isHappy` (bool), `mood` (number) — already mapped in `RivePetView.apply(_:)`
- [ ] Per-species art (blob / cat / dragon) driven by `Species`
- [ ] App icon — add `AppIcon.appiconset` (removed in v0; **required before any distribution**)

### Cross-device sync (replace `NoopPetSync`)
- [ ] CloudKit as source of truth for iPhone/iPad/Mac (SwiftData+CloudKit, or Point-Free SQLiteData if record sharing / public data is needed)
- [ ] WatchConnectivity for real-time phone↔watch (watch stays a thin client — SwiftData+CloudKit is unreliable on watchOS)
- [ ] Make the pet's CloudKit model all-optional / no unique constraints (already structured this way)

### Onboarding & gameplay loop
- [ ] First-run flow: name + species picker (pet creation)
- [ ] Local notifications + **AlarmKit** for neglected/feeding-time alerts (bypass silent mode, render in Dynamic Island/StandBy/Watch)
- [ ] Richer simulation: sickness, aging, evolution stages, mini-games

---

## 🎯 Polish — lean into the "wow" surfaces

### Live Activity / Dynamic Island / widgets
- [ ] iOS 27-only (gate behind `if #available(iOS 27, *)`): landscape Dynamic Island, StandBy bedside scene, `.supplementalActivityFamilies([.small])` → flows to Apple Watch Smart Stack + CarPlay
- [ ] Server-driven mood: ActivityKit push (per-device, push-to-start, broadcast channel) + `staleDate` decay; `WidgetPushHandler` for widgets
- [ ] `systemExtraLarge` / extra-large home-screen widgets; macOS desktop widgets
- [ ] Control Center controls (Controls API): "Feed" button + "Sleep" toggle
- [ ] Interactive snippets (`SnippetIntent`) — "Hey Siri, how's my pet?" shows a live mini card with a Feed button

### Watch
- [ ] Dedicated compact watch UI (currently reuses `PetHomeView` in a ScrollView)
- [ ] Complications via WidgetKit accessory families (circular hunger ring, corner, inline, rectangular mini-scene)
- [ ] Smart Stack relevance (`RelevantContext`)

### Siri / Spotlight (App Intents 2.0 / App Schemas)
- [ ] Adopt App Schemas (WWDC26) for the new Apple-Intelligence Siri
- [ ] Contribute pet entities to the Spotlight semantic index

---

## 🧱 Architecture & features to grow into

- [ ] Feature modules beyond Home: `Care`, `Store`, `Stats`, `Settings` — each with an Example preview app (Tuist TMA)
- [ ] Routing layer for cross-feature navigation (features never import each other)
- [ ] `swift-dependencies` for DI test seams (or keep Environment until needed)
- [ ] StoreKit: cosmetics / subscriptions (study Backyard Birds `ProductView`/`SubscriptionStoreView`)

---

## 🧪 Quality, accessibility, distribution

- [ ] Snapshot tests (pointfreeco/swift-snapshot-testing) for **static** UI only — never pixel-snapshot shaders/Liquid Glass/animations
- [ ] XCUITest flows driven by `accessibilityIdentifier`; `performAccessibilityAudit()` gate; `XCTHitchMetric` to guard animation smoothness
- [ ] Periphery dead-code scan + `xccov` coverage gate in CI
- [ ] Accessibility pass: VoiceOver, Dynamic Type, Reduce Motion / Reduce Transparency / Increase Contrast (glass + shaders must degrade gracefully)
- [ ] Quality tiers: gate shader complexity / particle counts on device class + `ProcessInfo.thermalState`; calm fallback under thermal/low-power
- [ ] Localization (currently `en` only)
- [ ] TestFlight via Fastlane `beta` lane (App Store Connect API key in `.env`); consider Xcode Cloud or a self-hosted Mac runner for device UI tests

---

## ⚠️ Known limitations / gotchas

- **App icon missing** — `AppIcon.appiconset` removed for v0; add before distribution.
- **Rive asset is a placeholder** (`Bear.riv`); swap for the real pet.
- **Device signing**: full app (App Group + widget) needs `-allowProvisioningUpdates` with a valid Apple ID session (Team `Z89YV44V6R`). The basic app signs with the existing wildcard profile.
- **watchOS** has no Metal → no SwiftUI shaders / RealityKit / Rive there; keep the Canvas tier.
- **Liquid Glass** is for functional chrome only (never over the pet/content).
- **Targeting**: built on stable Xcode 26.5 / iOS 26 floor; bump to iOS 27 when it ships (~fall 2026) to unlock the gated features above.
