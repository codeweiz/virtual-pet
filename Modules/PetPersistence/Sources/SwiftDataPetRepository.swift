import Foundation
import PetKit

#if canImport(SwiftData)
    import SwiftData

    /// SwiftData-backed persistence. The model is intentionally CloudKit-compatible:
    /// all properties have defaults and there are no unique constraints, which is
    /// what `NSPersistentCloudKitContainer` (SwiftData + CloudKit) requires.
    @Model
    final class PetRecord {
        var id: UUID = UUID()
        var name: String = "Mochi"
        var speciesRaw: String = Species.blob.rawValue
        var hunger: Double = 0.8
        var energy: Double = 0.8
        var happiness: Double = 0.8
        var hygiene: Double = 0.8
        var isAsleep: Bool = false
        var birthdate: Date = Date.now
        var lastInteraction: Date = Date.now

        init() {}

        func apply(_ s: PetSnapshot) {
            id = s.id
            name = s.name
            speciesRaw = s.species.rawValue
            hunger = s.stats.hunger
            energy = s.stats.energy
            happiness = s.stats.happiness
            hygiene = s.stats.hygiene
            isAsleep = s.isAsleep
            birthdate = s.birthdate
            lastInteraction = s.lastInteraction
        }

        var snapshot: PetSnapshot {
            PetSnapshot(
                id: id,
                name: name,
                species: Species(rawValue: speciesRaw) ?? .blob,
                stats: PetStats(
                    hunger: hunger, energy: energy, happiness: happiness, hygiene: hygiene),
                isAsleep: isAsleep,
                birthdate: birthdate,
                lastInteraction: lastInteraction
            )
        }
    }

    /// Local-first SwiftData repository. `ModelContext` is not `Sendable`, so the
    /// nonisolated async API hops to the main actor to touch `mainContext` and only
    /// ever returns the `Sendable` `PetSnapshot` across the boundary. `PetRecord`
    /// never escapes the main actor. (Heavy batch work should move to a
    /// `@ModelActor` — left as an extension point.)
    ///
    /// `Sendable`-conformant: the only stored property is an immutable, Sendable
    /// `ModelContainer`.
    public final class SwiftDataPetRepository: PetRepository {
        private let container: ModelContainer

        public init(inMemory: Bool = false) throws {
            let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            self.container = try ModelContainer(for: PetRecord.self, configurations: config)
        }

        public func load() async throws -> PetSnapshot? {
            let container = self.container
            return try await MainActor.run {
                try container.mainContext.fetch(FetchDescriptor<PetRecord>()).first?.snapshot
            }
        }

        public func save(_ snapshot: PetSnapshot) async throws {
            let container = self.container
            try await MainActor.run {
                let context = container.mainContext
                let record =
                    try context.fetch(FetchDescriptor<PetRecord>()).first
                    ?? {
                        let new = PetRecord()
                        context.insert(new)
                        return new
                    }()
                record.apply(snapshot)
                try context.save()
            }
        }
    }
#endif
