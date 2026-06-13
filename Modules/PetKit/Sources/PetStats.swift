import Foundation

/// The four core needs of a pet, each normalized to `0...1`
/// (`0` = critical, `1` = fully satisfied). Value type, `Sendable`, `Codable`.
public struct PetStats: Codable, Sendable, Hashable {
    public var hunger: Double
    public var energy: Double
    public var happiness: Double
    public var hygiene: Double

    public init(
        hunger: Double = 0.8,
        energy: Double = 0.8,
        happiness: Double = 0.8,
        hygiene: Double = 0.8
    ) {
        self.hunger = hunger.clamped()
        self.energy = energy.clamped()
        self.happiness = happiness.clamped()
        self.hygiene = hygiene.clamped()
    }

    /// Mean of all needs — a quick overall wellbeing readout in `0...1`.
    public var overall: Double { (hunger + energy + happiness + hygiene) / 4 }
}

extension Double {
    /// Clamp into a closed range (defaults to the unit interval).
    func clamped(to range: ClosedRange<Double> = 0...1) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
