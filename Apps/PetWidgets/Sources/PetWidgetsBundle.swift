import AppIntents
import DesignSystem
import PetIntents
import PetKit
import PetPersistence
import PetWidgetShared
import SwiftUI
import WidgetKit

// MARK: - Home / Lock Screen widget (interactive)

struct PetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (PetWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetWidgetEntry>) -> Void)
    {
        // Refresh on its own cadence; the Feed button also forces a reload.
        completion(
            Timeline(entries: [currentEntry()], policy: .after(.now.addingTimeInterval(900))))
    }

    private func currentEntry() -> PetWidgetEntry {
        if let pet = SharedPetStore().load() {
            PetWidgetEntry(pet: pet)
        } else {
            .placeholder
        }
    }
}

struct PetWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PetWidgetEntry

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular
    }

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.pet.mood.symbolName)
                .font(.title)
                .foregroundStyle(PetPalette.periwinkle)
                .contentTransition(.symbolEffect(.replace))
            Text(entry.pet.name).font(.petCaption)
            if !isAccessory {
                Text(entry.pet.mood.label).font(.caption2).foregroundStyle(.secondary)
                Button(intent: FeedPetIntent()) {
                    Label("Feed", systemImage: "fork.knife")
                }
                .buttonStyle(.borderedProminent)
                .tint(PetPalette.coral)
                .controlSize(.small)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

struct PetStatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PetStatusWidget", provider: PetProvider()) { entry in
            PetWidgetView(entry: entry)
        }
        .configurationDisplayName("Pet Status")
        .description("See and feed your pet at a glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Live Activity / Dynamic Island

struct PetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetActivityAttributes.self) { context in
            // Lock Screen / banner presentation.
            HStack(spacing: 12) {
                Image(systemName: context.state.mood.symbolName)
                    .font(.title2)
                    .foregroundStyle(PetPalette.periwinkle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.petName).font(.headline)
                    Text(context.state.mood.label).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(intent: FeedPetIntent()) {
                    Image(systemName: "fork.knife")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .activityBackgroundTint(PetPalette.periwinkle.opacity(0.18))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.mood.symbolName)
                        .font(.title2)
                        .foregroundStyle(PetPalette.periwinkle)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.petName).font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.mood.label).font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: FeedPetIntent()) {
                        Label("Feed", systemImage: "fork.knife")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PetPalette.coral)
                }
            } compactLeading: {
                Image(systemName: context.state.mood.symbolName)
            } compactTrailing: {
                Text("\(Int(context.state.stats.hunger * 100))%")
            } minimal: {
                Image(systemName: context.state.mood.symbolName)
            }
        }
    }
}

@main
struct PetWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PetStatusWidget()
        PetLiveActivity()
    }
}
