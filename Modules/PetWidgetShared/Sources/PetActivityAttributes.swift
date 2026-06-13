import Foundation
import PetKit

#if canImport(ActivityKit)
    import ActivityKit

    /// Live Activity / Dynamic Island data model. Lives in this shared module so the
    /// app (which starts/updates the activity) and the widget extension (which
    /// renders it) agree on the exact type.
    ///
    /// The dynamic `ContentState` is what gets pushed via ActivityKit updates
    /// (per-device, push-to-start, or broadcast channel) to keep the pet's mood
    /// live in the Dynamic Island.
    public struct PetActivityAttributes: ActivityAttributes, Sendable {
        public struct ContentState: Codable, Hashable, Sendable {
            public var stats: PetStats
            public var isAsleep: Bool
            public var moodRaw: String

            public init(stats: PetStats, isAsleep: Bool, mood: Mood) {
                self.stats = stats
                self.isAsleep = isAsleep
                self.moodRaw = mood.rawValue
            }

            public var mood: Mood { Mood(rawValue: moodRaw) ?? .content }
        }

        public var petName: String
        public var speciesRaw: String

        public init(petName: String, species: Species) {
            self.petName = petName
            self.speciesRaw = species.rawValue
        }

        public var species: Species { Species(rawValue: speciesRaw) ?? .blob }
    }
#endif
