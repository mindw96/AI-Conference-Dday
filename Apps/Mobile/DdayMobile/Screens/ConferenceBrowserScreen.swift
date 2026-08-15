import DdayCore
import SwiftUI

struct ConferenceBrowserScreen: View {
    @EnvironmentObject private var model: MobileAppModel

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(ConferenceSubcategory.allCases, id: \.rawValue) { subcategory in
                    Button {
                        model.toggleSubcategory(subcategory)
                    } label: {
                        HStack {
                            Text(model.text.subcategoryTitle(subcategory))
                            Spacer()
                            if model.isSubcategorySelected(subcategory) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle(model.text.categories)
        } content: {
            List {
                ForEach(model.selectedSubcategories, id: \.rawValue) { subcategory in
                    let conferences = model.conferences(in: subcategory)
                    if !conferences.isEmpty {
                        Section(model.text.subcategoryTitle(subcategory)) {
                            ForEach(conferences) { conference in
                                NavigationLink {
                                    ConferenceDetailScreen(conference: conference)
                                } label: {
                                    ConferenceRow(conference: conference)
                                }
                            }
                        }
                    }

                    let pastConferences = model.pastConferences(in: subcategory)
                    if !pastConferences.isEmpty {
                        Section("\(model.text.subcategoryTitle(subcategory)) - \(model.text.pastConferences)") {
                            ForEach(pastConferences) { conference in
                                NavigationLink {
                                    ConferenceDetailScreen(conference: conference)
                                } label: {
                                    ConferenceRow(conference: conference)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(
                model.selectedSubcategories.count == 1
                    ? model.text.subcategoryTitle(model.firstSelectedSubcategory)
                    : model.text.selectedCategories
            )
        } detail: {
            if let conference = model.selectedCategoryConferences().first {
                ConferenceDetailScreen(conference: conference)
            } else {
                ContentUnavailableView(
                    model.text.noConferences,
                    systemImage: "calendar.badge.exclamationmark"
                )
            }
        }
    }
}

private struct ConferenceRow: View {
    @EnvironmentObject private var model: MobileAppModel
    let conference: Conference

    var body: some View {
        let summary = model.summary(for: conference)

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conference.name)
                    .fontWeight(.semibold)
                if let summary {
                    Text(summary.deadlineLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let summary {
                Text(summary.display.text)
                    .font(.headline.monospacedDigit())
            }
        }
    }
}

private struct ConferenceDetailScreen: View {
    @EnvironmentObject private var model: MobileAppModel
    let conference: Conference

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(conference.fullName)
                        .font(.headline)
                    Text("\(conference.location) - \(conference.year)")
                        .foregroundStyle(.secondary)
                }
            }

            Section(model.text.deadlines) {
                ForEach(model.summaries(for: conference)) { summary in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(summary.deadlineLabel)
                                Text(summary.sourceDateText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(summary.display.text)
                                .font(.headline.monospacedDigit())
                        }

                        Button {
                            model.select(summary.source)
                        } label: {
                            Label(
                                model.isSelected(summary.source) ? model.text.selected : model.text.setMainDday,
                                systemImage: model.isSelected(summary.source) ? "checkmark.circle.fill" : "pin"
                            )
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                if conference.websiteUrl.isWebURL {
                    Link(model.text.openConferenceWebsite, destination: conference.websiteUrl)
                }
                if conference.sourceUrl.isWebURL {
                    Link(model.text.openSourcePage, destination: conference.sourceUrl)
                }
            }
        }
        .navigationTitle(conference.name)
    }
}

#Preview {
    ConferenceBrowserScreen()
        .environmentObject(MobileAppModel())
}
