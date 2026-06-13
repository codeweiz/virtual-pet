import PetKit
import PetRenderer
import RiveRuntime
import SwiftUI

/// Rive-backed pet for iPhone / iPad / Mac. Loads `pet.riv` from this module's
/// bundle, plays its default state machine, and maps the pet's mood to
/// state-machine inputs (best-effort — unknown inputs are ignored, so this works
/// with the placeholder `Bear.riv` today and with your own `pet.riv` later).
///
/// TO SHIP YOUR OWN PET: replace `Resources/pet.riv` with a creature designed in
/// the Rive editor that exposes the inputs referenced in `apply(_:)` below. Falls
/// back to the Canvas pet if the asset is missing (and watchOS uses Canvas only —
/// no Rive/Metal there).
public struct RivePetView: View {
    private let mood: Mood
    public init(mood: Mood) { self.mood = mood }

    public var body: some View {
        if Bundle.module.url(forResource: "pet", withExtension: "riv") != nil {
            RiveBackedPet(mood: mood)
        } else {
            CanvasPetView(mood: mood)  // graceful fallback
        }
    }
}

private struct RiveBackedPet: View {
    let mood: Mood
    @StateObject private var model = RiveViewModel(fileName: "pet", in: .module)

    var body: some View {
        model.view()
            .onAppear { apply(mood) }
            .onChange(of: mood) { _, newValue in apply(newValue) }
    }

    /// Input contract for a custom `pet.riv`. Every call is a safe no-op if the
    /// named input doesn't exist in the loaded file.
    private func apply(_ mood: Mood) {
        model.setInput("isAsleep", value: mood == .sleeping)
        model.setInput("isHappy", value: mood == .happy || mood == .content)
        model.setInput("mood", value: Double(moodLevel(mood)))
    }

    private func moodLevel(_ mood: Mood) -> Int {
        switch mood {
        case .happy: 4
        case .content: 3
        case .hungry, .dirty: 2
        case .tired, .sad: 1
        case .sleeping: 0
        }
    }
}
