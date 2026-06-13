import Foundation

/// What kind of creature the pet is. Drives art selection downstream.
public enum Species: String, Codable, Sendable, CaseIterable {
    case blob, cat, dragon

    public var displayName: String {
        switch self {
        case .blob: "Blob"
        case .cat: "Cat"
        case .dragon: "Dragon"
        }
    }
}

/// Derived emotional state. Maps to an SF Symbol and a human label so UI,
/// widgets, and complications can all render it consistently.
public enum Mood: String, Sendable, CaseIterable {
    case happy, content, hungry, tired, dirty, sad, sleeping

    public var symbolName: String {
        switch self {
        case .happy: "face.smiling.inverse"
        case .content: "face.smiling"
        case .hungry: "fork.knife"
        case .tired: "zzz"
        case .dirty: "bubbles.and.sparkles"
        case .sad: "cloud.rain"
        case .sleeping: "moon.zzz.fill"
        }
    }

    public var label: String {
        switch self {
        case .happy: "Happy"
        case .content: "Content"
        case .hungry: "Hungry"
        case .tired: "Tired"
        case .dirty: "Needs a wash"
        case .sad: "Lonely"
        case .sleeping: "Sleeping"
        }
    }
}

/// A care interaction the player can perform — also the vocabulary mirrored by
/// `PetIntents` so Siri / widgets / Control Center trigger the same effects.
public enum CareAction: String, Sendable, CaseIterable {
    case feed, play, clean, sleep, wake
}
