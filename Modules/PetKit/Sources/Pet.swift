import Foundation
import Observation

/// The live, observable pet. Held by the UI layer; mutating `stats`/`isAsleep`
/// automatically notifies SwiftUI via the Observation framework.
@Observable
public final class Pet {
    public let id: UUID
    public var name: String
    public var species: Species
    public var stats: PetStats
    public var isAsleep: Bool
    public let birthdate: Date
    public var lastInteraction: Date

    public init(
        id: UUID = UUID(),
        name: String,
        species: Species = .blob,
        stats: PetStats = .init(),
        isAsleep: Bool = false,
        birthdate: Date = .now,
        lastInteraction: Date = .now
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.stats = stats
        self.isAsleep = isAsleep
        self.birthdate = birthdate
        self.lastInteraction = lastInteraction
    }

    /// Derived emotional state.
    public var mood: Mood { PetSimulator.mood(for: stats, asleep: isAsleep) }

    /// A Sendable, Codable value snapshot for persistence / sync / widgets.
    public func snapshot() -> PetSnapshot {
        PetSnapshot(
            id: id, name: name, species: species, stats: stats,
            isAsleep: isAsleep, birthdate: birthdate, lastInteraction: lastInteraction
        )
    }

    public convenience init(snapshot s: PetSnapshot) {
        self.init(
            id: s.id, name: s.name, species: s.species, stats: s.stats,
            isAsleep: s.isAsleep, birthdate: s.birthdate, lastInteraction: s.lastInteraction
        )
    }

    public static var sample: Pet { Pet(name: "Mochi", species: .blob) }
}

/// Immutable, `Sendable` representation of a pet — crosses actor / process /
/// device boundaries (persistence, CloudKit, WatchConnectivity, widgets).
public struct PetSnapshot: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var species: Species
    public var stats: PetStats
    public var isAsleep: Bool
    public var birthdate: Date
    public var lastInteraction: Date

    public init(
        id: UUID = UUID(),
        name: String,
        species: Species = .blob,
        stats: PetStats = .init(),
        isAsleep: Bool = false,
        birthdate: Date = .now,
        lastInteraction: Date = .now
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.stats = stats
        self.isAsleep = isAsleep
        self.birthdate = birthdate
        self.lastInteraction = lastInteraction
    }

    public var mood: Mood { PetSimulator.mood(for: stats, asleep: isAsleep) }
}
