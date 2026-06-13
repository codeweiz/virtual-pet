#if canImport(ActivityKit)
    import ActivityKit
    import Foundation
    import PetKit
    import PetWidgetShared

    /// Manages the pet's Live Activity (Lock Screen + Dynamic Island). iOS-only —
    /// the file compiles away on macOS/watchOS where ActivityKit doesn't exist.
    ///
    /// We never *store* the `Activity` handle (it's non-Sendable and storing it as
    /// main-actor state trips Swift 6's region isolation). Instead we enumerate
    /// `Activity.activities` on demand, which yields fresh, freely-sendable values.
    @MainActor
    final class LiveActivityController {
        private typealias PetActivity = Activity<PetActivityAttributes>

        func start(for pet: Pet) {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
            guard PetActivity.activities.isEmpty else { return }  // avoid duplicates
            let attributes = PetActivityAttributes(petName: pet.name, species: pet.species)
            _ = try? Activity.request(
                attributes: attributes,
                content: ActivityContent(state: makeState(pet), staleDate: nil)
            )
        }

        func update(for pet: Pet) async {
            let content = ActivityContent(state: makeState(pet), staleDate: nil)
            for activity in PetActivity.activities {
                await activity.update(content)
            }
        }

        func stop() async {
            for activity in PetActivity.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }

        private func makeState(_ pet: Pet) -> PetActivityAttributes.ContentState {
            PetActivityAttributes.ContentState(
                stats: pet.stats, isAsleep: pet.isAsleep, mood: pet.mood)
        }
    }
#endif
