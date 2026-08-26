import SwiftUI
import WidgetKit

struct DeadlineWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: MobileWidgetDeadlineSnapshot
    let appearance: MobileWidgetAppearance
}

struct DeadlineWidgetProvider: TimelineProvider {
    private let store = MobileWidgetSnapshotStore()

    func placeholder(in context: Context) -> DeadlineWidgetEntry {
        DeadlineWidgetEntry(
            date: Date(),
            snapshot: .placeholder,
            appearance: .standard
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (DeadlineWidgetEntry) -> Void
    ) {
        let now = Date()
        completion(
            DeadlineWidgetEntry(
                date: now,
                snapshot: (store.load() ?? .empty).refreshed(now: now),
                appearance: store.loadAppearance()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<DeadlineWidgetEntry>) -> Void
    ) {
        let now = Date()
        let snapshot = store.load() ?? .empty
        let appearance = store.loadAppearance()
        let entries = MobileWidgetTimelinePlanner.entryDates(
            now: now,
            snapshot: snapshot
        ).map { entryDate in
            DeadlineWidgetEntry(
                date: entryDate,
                snapshot: snapshot.refreshed(now: entryDate),
                appearance: appearance
            )
        }
        let nextRefresh = MobileWidgetTimelinePlanner.nextDailyRefresh(after: now)
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }
}

struct DeadlineWidget: Widget {
    let kind = "DdayDeadlineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DeadlineWidgetProvider()) { entry in
            DeadlineWidgetView(entry: entry)
        }
        .configurationDisplayName("Dday")
        .description("Shows your selected conference deadline.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

private struct DeadlineWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode
    let entry: DeadlineWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            withWidgetBackground {
                SmallDeadlineWidget(
                    snapshot: entry.snapshot,
                    appearance: entry.appearance
                )
            }
        case .systemMedium:
            withWidgetBackground {
                MediumDeadlineWidget(
                    snapshot: entry.snapshot,
                    appearance: entry.appearance
                )
            }
        case .systemLarge:
            withWidgetBackground {
                LargeDeadlineWidget(
                    snapshot: entry.snapshot,
                    appearance: entry.appearance
                )
            }
        case .systemExtraLarge:
            withWidgetBackground {
                ExtraLargeDeadlineWidget(
                    snapshot: entry.snapshot,
                    appearance: entry.appearance
                )
            }
        case .accessoryCircular:
            CircularDeadlineWidget(snapshot: entry.snapshot)
        case .accessoryRectangular:
            RectangularDeadlineWidget(snapshot: entry.snapshot)
        case .accessoryInline:
            Text("\(entry.snapshot.title) \(entry.snapshot.deadlineText)")
                .font(.headline)
        default:
            withWidgetBackground {
                SmallDeadlineWidget(
                    snapshot: entry.snapshot,
                    appearance: entry.appearance
                )
            }
        }
    }

    @ViewBuilder
    private func withWidgetBackground<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .overlay {
                if renderingMode == .fullColor,
                   entry.appearance.background == .glass {
                    ContainerRelativeShape()
                        .stroke(Color.white.opacity(0.58), lineWidth: 0.8)
                        .padding(1)
                }
            }
            .containerBackground(for: .widget) {
                WidgetBackgroundView(appearance: entry.appearance)
            }
    }
}

private struct WidgetBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme
    let appearance: MobileWidgetAppearance

    var body: some View {
        switch appearance.background {
        case .system:
            Color(uiColor: .systemBackground)
        case .glass:
            ZStack {
                Color(uiColor: .systemBackground)
                appearance.backgroundRGB.widgetColor
                    .opacity(colorScheme == .dark ? 0.2 : 0.11)
            }
        case .white:
            Color.white
        case .black:
            Color.black
        case .navy:
            Color(red: 0.07, green: 0.11, blue: 0.22)
        }
    }
}

private struct SmallDeadlineWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let snapshot: MobileWidgetDeadlineSnapshot
    let appearance: MobileWidgetAppearance

    private var palette: WidgetPalette {
        WidgetPalette(appearance: appearance, renderingMode: renderingMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.title)
                .font(.system(size: 28, weight: .bold, design: .default))
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundStyle(palette.primary)

            Text(snapshot.deadlineText)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .widgetAccentable()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .foregroundStyle(palette.primary)

            Text(snapshot.deadlineLabel)
                .font(.callout)
                .foregroundStyle(palette.secondary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct MediumDeadlineWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let snapshot: MobileWidgetDeadlineSnapshot
    let appearance: MobileWidgetAppearance

    private var palette: WidgetPalette {
        WidgetPalette(appearance: appearance, renderingMode: renderingMode)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(snapshot.title)
                    .font(.system(size: 38, weight: .bold, design: .default))
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .foregroundStyle(palette.primary)

                Text(snapshot.deadlineLabel)
                    .font(.callout)
                    .foregroundStyle(palette.secondary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(snapshot.localDateText)
                    .font(.caption2)
                    .foregroundStyle(palette.secondary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            Text(snapshot.deadlineText)
                .font(.system(size: 66, weight: .bold, design: .rounded))
                .monospacedDigit()
                .widgetAccentable()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .layoutPriority(2)
                .foregroundStyle(palette.primary)
        }
        .padding(12)
    }
}

private struct LargeDeadlineWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let snapshot: MobileWidgetDeadlineSnapshot
    let appearance: MobileWidgetAppearance

    private var palette: WidgetPalette {
        WidgetPalette(appearance: appearance, renderingMode: renderingMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Main D-Day")
                .font(.headline)
                .foregroundStyle(palette.secondary)

            Text(snapshot.title)
                .font(.system(size: 52, weight: .bold, design: .default))
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .foregroundStyle(palette.primary)

            Text(snapshot.deadlineText)
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .monospacedDigit()
                .widgetAccentable()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .foregroundStyle(palette.primary)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.deadlineLabel)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(palette.primary)

                Text(snapshot.localDateText)
                    .font(.callout)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(palette.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(24)
    }
}

private struct ExtraLargeDeadlineWidget: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let snapshot: MobileWidgetDeadlineSnapshot
    let appearance: MobileWidgetAppearance

    private var palette: WidgetPalette {
        WidgetPalette(appearance: appearance, renderingMode: renderingMode)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Main D-Day")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.secondary)

                Text(snapshot.title)
                    .font(.system(size: 64, weight: .bold, design: .default))
                    .minimumScaleFactor(0.65)
                    .lineLimit(1)
                    .foregroundStyle(palette.primary)

                Text(snapshot.deadlineLabel)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(palette.primary)

                Text(snapshot.localDateText)
                    .font(.title3)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(palette.secondary)
            }
            .layoutPriority(1)

            Spacer(minLength: 0)

            Text(snapshot.deadlineText)
                .font(.system(size: 126, weight: .bold, design: .rounded))
                .monospacedDigit()
                .widgetAccentable()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
                .layoutPriority(2)
                .foregroundStyle(palette.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(30)
    }
}

private struct CircularDeadlineWidget: View {
    let snapshot: MobileWidgetDeadlineSnapshot

    var body: some View {
        VStack(spacing: 2) {
            Text(snapshot.title)
                .font(.caption)
                .fontWeight(.bold)
                .minimumScaleFactor(0.65)
                .lineLimit(1)

            Text(snapshot.deadlineText)
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
                .minimumScaleFactor(0.45)
                .lineLimit(1)
        }
    }
}

private struct RectangularDeadlineWidget: View {
    let snapshot: MobileWidgetDeadlineSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(snapshot.title) \(snapshot.deadlineText)")
                .font(.title3)
                .fontWeight(.bold)
                .monospacedDigit()
                .minimumScaleFactor(0.65)
                .lineLimit(1)

            Text(snapshot.deadlineLabel)
                .font(.callout)
                .foregroundStyle(.secondary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
}

#Preview(as: .systemSmall) {
    DeadlineWidget()
} timeline: {
    DeadlineWidgetEntry(date: Date(), snapshot: .placeholder, appearance: .standard)
}

#Preview(as: .systemLarge) {
    DeadlineWidget()
} timeline: {
    DeadlineWidgetEntry(date: Date(), snapshot: .placeholder, appearance: .standard)
}

#Preview(as: .systemExtraLarge) {
    DeadlineWidget()
} timeline: {
    DeadlineWidgetEntry(date: Date(), snapshot: .placeholder, appearance: .standard)
}

#Preview(as: .accessoryRectangular) {
    DeadlineWidget()
} timeline: {
    DeadlineWidgetEntry(date: Date(), snapshot: .placeholder, appearance: .standard)
}

private struct WidgetPalette {
    let primary: Color
    let secondary: Color

    init(
        appearance: MobileWidgetAppearance,
        renderingMode: WidgetRenderingMode
    ) {
        guard renderingMode == .fullColor else {
            primary = .primary
            secondary = .secondary
            return
        }

        switch appearance.textColor {
        case .automatic:
            switch appearance.background {
            case .system, .glass:
                primary = .primary
                secondary = .secondary
            case .white:
                primary = .black
                secondary = .black.opacity(0.58)
            case .black, .navy:
                primary = .white
                secondary = .white.opacity(0.7)
            }
        case .black:
            primary = .black
            secondary = .black.opacity(0.58)
        case .white:
            primary = .white
            secondary = .white.opacity(0.7)
        case .custom:
            primary = appearance.textRGB.widgetColor
            secondary = appearance.textRGB.widgetColor.opacity(0.68)
        }
    }
}

private extension MobileWidgetRGBColor {
    var widgetColor: Color {
        Color(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }
}
