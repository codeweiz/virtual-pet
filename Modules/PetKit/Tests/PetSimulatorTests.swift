import Foundation
import Testing

@testable import PetKit

@Suite("Pet simulation rules")
struct PetSimulatorTests {

    @Test("Hunger decays while awake")
    func hungerDecaysWhileAwake() {
        let start = PetStats(hunger: 1.0)
        let after = PetSimulator.advance(start, by: 600, asleep: false)  // 10 min
        #expect(after.hunger < start.hunger)
        #expect(after.hunger >= 0)
    }

    @Test("Sleeping restores energy")
    func sleepingRestoresEnergy() {
        let start = PetStats(energy: 0.2)
        let after = PetSimulator.advance(start, by: 600, asleep: true)
        #expect(after.energy > start.energy)
    }

    @Test("Feeding raises the hunger need and never overflows")
    func feedingIncreasesHungerStat() {
        let fed = PetStats(hunger: 0.3).applying(.feed)
        #expect(fed.hunger > 0.3)
        #expect(fed.hunger <= 1.0)
    }

    @Test("Low hunger surfaces a hungry mood")
    func moodIsHungryWhenLow() {
        #expect(PetSimulator.mood(for: PetStats(hunger: 0.1), asleep: false) == .hungry)
    }

    @Test("Stats clamp into the unit interval")
    func statsClampToUnitRange() {
        let s = PetStats(hunger: 5, energy: -3)
        #expect(s.hunger == 1.0)
        #expect(s.energy == 0.0)
    }

    @Test("Sleeping mood takes priority over unmet needs")
    func sleepingMoodWins() {
        #expect(PetSimulator.mood(for: PetStats(hunger: 0.1), asleep: true) == .sleeping)
    }

    @Test("Snapshot round-trips losslessly")
    func snapshotRoundTrip() {
        let pet = Pet(name: "Mochi", species: .dragon, stats: PetStats(hunger: 0.42))
        let restored = Pet(snapshot: pet.snapshot())
        #expect(restored.name == "Mochi")
        #expect(restored.species == .dragon)
        #expect(restored.stats.hunger == 0.42)
    }
}
