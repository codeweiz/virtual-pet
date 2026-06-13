import DesignSystem
import PetKit
import PetRenderer
import SwiftUI

/// The home screen: the live pet, its needs, and care controls. Adaptive enough
/// to run on iPhone/iPad/Mac and (compactly) on watchOS.
///
/// The pet view is injected so each platform picks its renderer: iOS/Mac pass a
/// Rive-backed view, watchOS uses the Canvas default (see the convenience init).
public struct PetHomeView<PetContent: View>: View {
    @State private var model: PetHomeModel
    @Environment(\.scenePhase) private var scenePhase
    private let petContent: (Mood) -> PetContent

    public init(
        model: PetHomeModel = PetHomeModel(),
        @ViewBuilder petContent: @escaping (Mood) -> PetContent
    ) {
        _model = State(initialValue: model)
        self.petContent = petContent
    }

    public var body: some View {
        VStack(spacing: PetMetrics.spacing) {
            header
            petContent(model.pet.mood)
                .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity)
                .animation(.smooth, value: model.pet.mood)
            statPanel
            careButtons
        }
        .padding()
        .task { await model.runSimulation() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.syncFromShared() }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text(model.pet.name)
                .font(.petTitle)
            Label(model.pet.mood.label, systemImage: model.pet.mood.symbolName)
                .font(.petCaption)
                .foregroundStyle(.secondary)
                .contentTransition(.symbolEffect(.replace))
        }
    }

    private var statPanel: some View {
        VStack(spacing: 10) {
            StatBar(
                value: model.pet.stats.hunger, tint: PetPalette.butter, systemImage: "fork.knife")
            StatBar(value: model.pet.stats.energy, tint: PetPalette.mint, systemImage: "bolt.fill")
            StatBar(
                value: model.pet.stats.happiness, tint: PetPalette.blush, systemImage: "heart.fill")
            StatBar(
                value: model.pet.stats.hygiene, tint: PetPalette.periwinkle,
                systemImage: "drop.fill")
        }
        .padding()
        .petGlass()
    }

    private var careButtons: some View {
        HStack(spacing: PetMetrics.spacing) {
            careButton("Feed", "fork.knife") { model.perform(.feed) }
            careButton("Play", "tennisball.fill") { model.perform(.play) }
            careButton("Clean", "bubbles.and.sparkles.fill") { model.perform(.clean) }
            careButton(
                model.pet.isAsleep ? "Wake" : "Sleep",
                model.pet.isAsleep ? "sun.max.fill" : "moon.fill"
            ) { model.toggleSleep() }
        }
    }

    private func careButton(
        _ title: String, _ symbol: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.title3)
                Text(title).font(.petCaption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }
}

extension PetHomeView where PetContent == CanvasPetView {
    /// Convenience init using the Canvas pet (watchOS + universal fallback).
    public init(model: PetHomeModel = PetHomeModel()) {
        self.init(model: model) { CanvasPetView(mood: $0) }
    }
}

#Preview {
    PetHomeView()
}
