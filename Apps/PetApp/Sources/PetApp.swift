import FeaturePetHome
import PetPersistence
import PetRendererRive
import SwiftUI
import VisualFX

@main
struct PetApp: App {
    // Durable local storage via SwiftData (falls back to in-memory if the store
    // can't be opened). The model also mirrors to the App Group for widgets.
    @State private var model = PetHomeModel(
        repository: (try? SwiftDataPetRepository()) ?? InMemoryPetRepository()
    )

    var body: some Scene {
        WindowGroup {
            ZStack {
                AuraBackground()  // GPU shader backdrop (iOS/iPad/Mac)
                PetHomeView(model: model) { RivePetView(mood: $0) }  // Rive-backed pet
            }
            #if os(macOS)
                .frame(minWidth: 400, minHeight: 600)
            #endif
        }
        #if os(macOS)
            .windowResizability(.contentSize)
        #endif
    }
}
