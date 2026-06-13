import Foundation
import PetKit
import WidgetKit

/// Timeline entry shared by every widget surface (Home Screen, Lock Screen,
/// StandBy, macOS desktop, and watch complications via accessory families).
public struct PetWidgetEntry: TimelineEntry, Sendable {
    public let date: Date
    public let pet: PetSnapshot

    public init(date: Date = .now, pet: PetSnapshot) {
        self.date = date
        self.pet = pet
    }

    public static var placeholder: PetWidgetEntry {
        PetWidgetEntry(pet: PetSnapshot(name: "Mochi"))
    }
}
