import Foundation
import Observation
import PetKit
import PetPersistence
import PetSync

#if canImport(WidgetKit)
    import WidgetKit
#endif

/// MV-pattern state holder for the home screen. MainActor-isolated (it drives
/// UI); the pure `PetSimulator` math could move off-main later.
///
/// Every change fans out to: the App Group store (so widgets/intents see it),
/// a widget-timeline reload, the cross-device sync channel, the Live Activity,
/// and (for explicit care actions) durable SwiftData storage.
@MainActor
@Observable
public final class PetHomeModel {
    public let pet: Pet
    private let repository: any PetRepository
    private let sync: any PetSyncing
    private let shared = SharedPetStore()
    private let tickInterval: Duration

    #if canImport(ActivityKit)
        private let presence = LiveActivityController()
    #endif

    public init(
        pet: Pet = .sample,
        repository: any PetRepository = InMemoryPetRepository(),
        sync: any PetSyncing = NoopPetSync(),
        tickInterval: Duration = .seconds(2)
    ) {
        self.pet = pet
        self.repository = repository
        self.sync = sync
        self.tickInterval = tickInterval
    }

    /// Restore persisted state, seed the shared store + Live Activity, then
    /// advance needs on a steady cadence until the owning view disappears.
    public func runSimulation() async {
        if let snapshot = (try? await repository.load()) ?? shared.load() {
            restore(from: snapshot)
        }
        shared.save(pet.snapshot())
        startPresence()
        while !Task.isCancelled {
            try? await Task.sleep(for: tickInterval)
            let seconds = Double(tickInterval.components.seconds)
            pet.stats = PetSimulator.advance(pet.stats, by: seconds, asleep: pet.isAsleep)
            await broadcast()
        }
    }

    public func perform(_ action: CareAction) {
        switch action {
        case .feed, .play, .clean:
            pet.stats = pet.stats.applying(action)
        case .sleep:
            pet.isAsleep = true
        case .wake:
            pet.isAsleep = false
        }
        pet.lastInteraction = .now
        Task { await broadcast(persistDurably: true) }
    }

    public func toggleSleep() {
        perform(pet.isAsleep ? .wake : .sleep)
    }

    /// Pick up changes a widget / App Intent made while we were backgrounded.
    public func syncFromShared() {
        guard let snapshot = shared.load() else { return }
        restore(from: snapshot)
    }

    public func startPresence() {
        #if canImport(ActivityKit)
            presence.start(for: pet)
        #endif
    }

    public func stopPresence() async {
        #if canImport(ActivityKit)
            await presence.stop()
        #endif
    }

    // MARK: - Private

    private func broadcast(persistDurably: Bool = false) async {
        let snapshot = pet.snapshot()
        shared.save(snapshot)  // App Group bridge → widgets & intents
        reloadWidgets()
        await sync.push(snapshot)  // cross-device (Noop until CloudKit/WC wired)
        #if canImport(ActivityKit)
            await presence.update(for: pet)
        #endif
        if persistDurably {
            try? await repository.save(snapshot)  // durable SwiftData
        }
    }

    private func restore(from snapshot: PetSnapshot) {
        pet.name = snapshot.name
        pet.species = snapshot.species
        pet.stats = snapshot.stats
        pet.isAsleep = snapshot.isAsleep
        pet.lastInteraction = snapshot.lastInteraction
    }

    private func reloadWidgets() {
        #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
