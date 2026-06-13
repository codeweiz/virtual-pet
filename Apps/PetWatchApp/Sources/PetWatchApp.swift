import FeaturePetHome
import SwiftUI

@main
struct PetWatchApp: App {
    var body: some Scene {
        WindowGroup {
            // The shared, adaptive home view. The pet renders via the Canvas tier
            // (no Metal on watchOS); scroll accommodates the small screen.
            ScrollView {
                PetHomeView()
            }
        }
    }
}
