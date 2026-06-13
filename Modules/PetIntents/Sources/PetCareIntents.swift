import AppIntents
import Foundation
import PetKit
import PetPersistence

#if canImport(WidgetKit)
    import WidgetKit
#endif

// One App Intents vocabulary, surfaced everywhere: Siri, Shortcuts, Spotlight,
// interactive widgets, Control Center controls, and Live Activity buttons.
// `perform()` mutates the shared App Group store (no app launch) and reloads the
// widget timelines so the change is visible immediately.

private func reloadWidgets() {
    #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
    #endif
}

public struct FeedPetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Feed Pet"
    public static let description = IntentDescription("Give your pet a meal.")
    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let pet = SharedPetStore().apply(.feed)
        reloadWidgets()
        return .result(dialog: "Yum! \(pet.name) has been fed. 🍙")
    }
}

public struct PlayWithPetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Play With Pet"
    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let pet = SharedPetStore().apply(.play)
        reloadWidgets()
        return .result(dialog: "Wheee! \(pet.name) had fun playing. ✨")
    }
}

public struct CleanPetIntent: AppIntent {
    public static let title: LocalizedStringResource = "Clean Pet"
    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let pet = SharedPetStore().apply(.clean)
        reloadWidgets()
        return .result(dialog: "Squeaky clean! ✨")
    }
}

public struct ToggleSleepIntent: AppIntent {
    public static let title: LocalizedStringResource = "Toggle Sleep"
    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = SharedPetStore()
        let isAsleep = store.load()?.isAsleep ?? false
        let pet = store.apply(isAsleep ? .wake : .sleep)
        reloadWidgets()
        return .result(dialog: pet.isAsleep ? "Sweet dreams. 🌙" : "Good morning! ☀️")
    }
}

public struct CheckPetStatusIntent: AppIntent {
    public static let title: LocalizedStringResource = "Check Pet Status"
    public init() {}

    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let pet = SharedPetStore().load() ?? PetSnapshot(name: "Your pet")
        return .result(dialog: "\(pet.name) is \(pet.mood.label.lowercased()). 🐾")
    }
}

// Buttons embedded in a Live Activity / Dynamic Island require LiveActivityIntent.
#if os(iOS)
    extension FeedPetIntent: LiveActivityIntent {}
    extension ToggleSleepIntent: LiveActivityIntent {}
#endif

/// Registers Siri phrases for the intents above.
public struct PetShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: FeedPetIntent(),
            phrases: ["Feed my pet in \(.applicationName)"],
            shortTitle: "Feed Pet",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: CheckPetStatusIntent(),
            phrases: ["How is my pet in \(.applicationName)"],
            shortTitle: "Pet Status",
            systemImageName: "heart.text.square"
        )
    }
}
