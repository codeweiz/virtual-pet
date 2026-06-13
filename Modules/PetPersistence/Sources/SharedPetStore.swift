import Foundation
import PetKit

/// App Group-backed snapshot store — the cross-process bridge between the app,
/// its widgets, and App Intents (interactive widget buttons / Control Center /
/// Live Activity actions). UserDefaults in the shared container is durable and
/// instantly readable from the widget & intent extension processes.
///
/// This is what makes the interactive loop work: a widget's Feed button runs
/// `FeedPetIntent` in the extension, which mutates THIS store; the app reads it
/// back when it returns to the foreground.
public struct SharedPetStore {
    public static let appGroupID = "group.com.microboat.virtualpet"
    private static let key = "pet.snapshot"

    private let defaults: UserDefaults

    public init(appGroupID: String = SharedPetStore.appGroupID) {
        // Falls back to .standard if the App Group isn't entitled (e.g. watchOS),
        // so callers are always safe — they just won't see cross-process data.
        self.defaults = UserDefaults(suiteName: appGroupID) ?? .standard
    }

    public func load() -> PetSnapshot? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(PetSnapshot.self, from: data)
    }

    public func save(_ snapshot: PetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.key)
    }

    /// Read → apply a care action → write back. Returns the updated snapshot.
    /// Seeds a default pet if the store is empty (first widget tap before launch).
    @discardableResult
    public func apply(_ action: CareAction) -> PetSnapshot {
        var snapshot = load() ?? PetSnapshot(name: "Mochi")
        switch action {
        case .feed, .play, .clean:
            snapshot.stats = snapshot.stats.applying(action)
        case .sleep:
            snapshot.isAsleep = true
        case .wake:
            snapshot.isAsleep = false
        }
        snapshot.lastInteraction = .now
        save(snapshot)
        return snapshot
    }
}
