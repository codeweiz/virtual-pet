import Foundation

/// Pure, deterministic game rules. No UI, no I/O, no clock — everything is a
/// function of inputs, which is exactly what makes it trivially unit-testable.
public enum PetSimulator {

    /// Advance needs forward by `seconds` of elapsed time. Decay rates are tuned
    /// per (normalized) minute. Sleeping restores energy and slows hunger.
    public static func advance(
        _ stats: PetStats,
        by seconds: TimeInterval,
        asleep: Bool
    ) -> PetStats {
        let minutes = seconds / 60.0
        var next = stats

        if asleep {
            next.energy = (next.energy + minutes * 0.50).clamped()
            next.hunger = (next.hunger - minutes * 0.10).clamped()
        } else {
            next.hunger = (next.hunger - minutes * 0.20).clamped()
            next.energy = (next.energy - minutes * 0.12).clamped()
            next.hygiene = (next.hygiene - minutes * 0.08).clamped()
        }

        // Happiness drifts toward how well the other needs are met.
        let care = (next.hunger + next.energy + next.hygiene) / 3
        next.happiness = (next.happiness + (care - next.happiness) * minutes * 0.50).clamped()
        return next
    }

    /// Classify the current emotional state. Order matters: urgent needs win.
    public static func mood(for stats: PetStats, asleep: Bool) -> Mood {
        if asleep { return .sleeping }
        if stats.hunger < 0.25 { return .hungry }
        if stats.energy < 0.25 { return .tired }
        if stats.hygiene < 0.25 { return .dirty }
        if stats.happiness < 0.35 { return .sad }
        if stats.overall > 0.75 { return .happy }
        return .content
    }
}

extension PetStats {
    /// Apply the immediate effect of a care action. Returns a new value.
    public func applying(_ action: CareAction) -> PetStats {
        var next = self
        switch action {
        case .feed:
            next.hunger = (next.hunger + 0.35).clamped()
            next.happiness = (next.happiness + 0.05).clamped()
        case .play:
            next.happiness = (next.happiness + 0.30).clamped()
            next.energy = (next.energy - 0.10).clamped()
            next.hunger = (next.hunger - 0.05).clamped()
        case .clean:
            next.hygiene = 1.0
            next.happiness = (next.happiness + 0.10).clamped()
        case .sleep, .wake:
            break  // handled by the Pet's `isAsleep` flag, not the stats
        }
        return next
    }
}
