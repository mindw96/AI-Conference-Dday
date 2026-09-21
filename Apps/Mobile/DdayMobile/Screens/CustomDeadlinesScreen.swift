import DdayCore
import SwiftUI

struct CustomDeadlinesScreen: View {
    @EnvironmentObject private var model: MobileAppModel
    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if model.customDeadlineSummaries.isEmpty {
                    ContentUnavailableView(
                        model.text.noCustomDeadlines,
                        systemImage: "calendar.badge.plus"
                    )
                } else {
                    ForEach(model.customDeadlineSummaries) { summary in
                        CustomDeadlineRow(summary: summary)
                    }
                }
            }
            .navigationTitle(model.text.customTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Label(model.text.addCustomDday, systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddCustomDeadlineSheet()
                    .environmentObject(model)
            }
        }
    }
}

private struct CustomDeadlineRow: View {
    @EnvironmentObject private var model: MobileAppModel
    let summary: MobileDeadlineSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.title)
                        .font(.headline)
                    Text(summary.deadlineLabel)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(summary.display.text)
                    .font(.title3.monospacedDigit().bold())
            }

            Text(summary.localDateText)
                .font(.caption)
                .foregroundStyle(.secondary)

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
        .padding(.vertical, 6)
        .swipeActions {
            Button(role: .destructive) {
                model.removeCustomDeadline(source: summary.source)
            } label: {
                Label(model.text.delete, systemImage: "trash")
            }
        }
    }
}

private struct AddCustomDeadlineSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var model: MobileAppModel

    @State private var name = ""
    @State private var label = "Deadline"
    @State private var date = Date()
    @State private var timezone: CustomDeadlineTimezone = .aoe

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(model.text.name, text: $name)
                    TextField(model.text.label, text: $label)
                    DatePicker(model.text.date, selection: $date)
                    Picker(model.text.timezone, selection: $timezone) {
                        Text("AoE").tag(CustomDeadlineTimezone.aoe)
                        Text(model.text.localTimezone).tag(CustomDeadlineTimezone.local)
                    }
                }
            }
            .navigationTitle(model.text.addCustomDday)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(model.text.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(model.text.save) {
                        model.addCustomDeadline(
                            name: name,
                            label: label,
                            date: date,
                            timezone: timezone
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CustomDeadlinesScreen()
        .environmentObject(MobileAppModel())
}
