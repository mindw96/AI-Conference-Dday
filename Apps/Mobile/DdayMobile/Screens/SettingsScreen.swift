import DdayCore
import SwiftUI
import UIKit

struct SettingsScreen: View {
    @EnvironmentObject private var model: MobileAppModel
    private let swatchColumns = [
        GridItem(.adaptive(minimum: 58, maximum: 72), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(model.text.languageLabel) {
                    Picker(model.text.languageLabel, selection: $model.appLanguage) {
                        ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                            Text(model.text.languageTitle(language)).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(model.text.data) {
                    Button {
                        Task {
                            await model.refreshConferenceData()
                        }
                    } label: {
                        HStack {
                            Text(model.text.checkConferenceListUpdates)
                            Spacer()
                            if model.isUpdatingData {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(model.isUpdatingData)

                    if let updateMessage = model.updateMessage {
                        Text(updateMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(model.text.widgetAppearance) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(model.text.widgetAppearanceDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.text.widgetBackground)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            LazyVGrid(columns: swatchColumns, alignment: .leading, spacing: 12) {
                                ForEach(MobileWidgetBackground.allCases, id: \.rawValue) { background in
                                    WidgetColorSwatch(
                                        title: model.text.widgetBackgroundTitle(background),
                                        color: background.previewColor(
                                            customRGB: model.widgetAppearance.backgroundRGB
                                        ),
                                        foreground: background.swatchForeground(
                                            customRGB: model.widgetAppearance.backgroundRGB
                                        ),
                                        selected: model.widgetAppearance.background == background
                                    ) {
                                        model.setWidgetBackground(background)
                                    }
                                }
                            }

                            if model.widgetAppearance.background == .glass {
                                RGBColorEditor(
                                    title: model.text.widgetGlassTint,
                                    rgbLabel: model.text.rgbValues,
                                    chooseColorLabel: model.text.chooseColor,
                                    value: model.widgetAppearance.backgroundRGB,
                                    onChange: model.setWidgetGlassTint
                                )
                            }
                        }

                        Divider()

                        VStack(alignment: .leading, spacing: 10) {
                            Text(model.text.widgetTextColor)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            LazyVGrid(columns: swatchColumns, alignment: .leading, spacing: 12) {
                                ForEach(MobileWidgetTextColor.allCases, id: \.rawValue) { textColor in
                                    WidgetColorSwatch(
                                        title: model.text.widgetTextColorTitle(textColor),
                                        color: textColor.previewColor(
                                            customRGB: model.widgetAppearance.textRGB
                                        ),
                                        foreground: textColor.swatchForeground(
                                            customRGB: model.widgetAppearance.textRGB
                                        ),
                                        selected: model.widgetAppearance.textColor == textColor
                                    ) {
                                        model.setWidgetTextColor(textColor)
                                    }
                                }
                            }

                            if model.widgetAppearance.textColor == .custom {
                                RGBColorEditor(
                                    title: model.text.widgetCustomTextColor,
                                    rgbLabel: model.text.rgbValues,
                                    chooseColorLabel: model.text.chooseColor,
                                    value: model.widgetAppearance.textRGB,
                                    onChange: model.setWidgetCustomTextColor
                                )
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section(model.text.notifications) {
                    Toggle(
                        model.text.enableNotifications,
                        isOn: Binding(
                            get: { model.notificationsEnabled },
                            set: { isEnabled in
                                Task {
                                    await model.setNotificationsEnabled(isEnabled)
                                }
                            }
                        )
                    )

                    Text(model.text.notificationDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if let notificationMessage = model.notificationMessage {
                        Text(notificationMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(model.text.privacy) {
                    Text(model.text.privacyBody)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(model.text.settingsTab)
        }
    }
}

private struct RGBColorEditor: View {
    let title: String
    let rgbLabel: String
    let chooseColorLabel: String
    let value: MobileWidgetRGBColor
    let onChange: (MobileWidgetRGBColor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text("\(rgbLabel) · \(value.hexText)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                ColorPicker(
                    chooseColorLabel,
                    selection: Binding(
                        get: { value.color },
                        set: { onChange(MobileWidgetRGBColor(color: $0)) }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
            }

            HStack(spacing: 10) {
                RGBChannelField(title: "R", value: channelBinding(\.red))
                RGBChannelField(title: "G", value: channelBinding(\.green))
                RGBChannelField(title: "B", value: channelBinding(\.blue))
            }
        }
        .padding(12)
        .background(
            Color.secondary.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func channelBinding(
        _ keyPath: WritableKeyPath<MobileWidgetRGBColor, Int>
    ) -> Binding<Int> {
        Binding(
            get: { value[keyPath: keyPath] },
            set: { newValue in
                var updated = value
                updated[keyPath: keyPath] = min(max(newValue, 0), 255)
                onChange(updated)
            }
        )
    }
}

private struct RGBChannelField: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            TextField(title, value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct WidgetColorSwatch: View {
    let title: String
    let color: Color
    let foreground: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color)
                        .frame(width: 54, height: 38)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: selected ? 2 : 1)
                        )

                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(foreground)
                    }
                }

                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(width: 58)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private extension MobileWidgetBackground {
    func previewColor(customRGB: MobileWidgetRGBColor) -> Color {
        switch self {
        case .system:
            return Color(.systemGray5)
        case .glass:
            return customRGB.color.opacity(0.72)
        case .white:
            return .white
        case .black:
            return .black
        case .navy:
            return Color(red: 0.07, green: 0.11, blue: 0.22)
        }
    }

    func swatchForeground(customRGB: MobileWidgetRGBColor) -> Color {
        switch self {
        case .black, .navy:
            return .white
        case .glass:
            return customRGB.swatchForeground
        case .system, .white:
            return .black
        }
    }
}

private extension MobileWidgetTextColor {
    func previewColor(customRGB: MobileWidgetRGBColor) -> Color {
        switch self {
        case .automatic:
            return Color(.systemGray4)
        case .black:
            return .black
        case .white:
            return .white
        case .custom:
            return customRGB.color
        }
    }

    func swatchForeground(customRGB: MobileWidgetRGBColor) -> Color {
        switch self {
        case .black:
            return .white
        case .custom:
            return customRGB.swatchForeground
        case .automatic, .white:
            return .black
        }
    }
}

private extension MobileWidgetRGBColor {
    var color: Color {
        Color(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: 1
        )
    }

    var hexText: String {
        String(format: "#%02X%02X%02X", red, green, blue)
    }

    var swatchForeground: Color {
        let luminance = (
            0.2126 * Double(red)
                + 0.7152 * Double(green)
                + 0.0722 * Double(blue)
        ) / 255
        return luminance > 0.58 ? .black : .white
    }

    init(color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            self.init(
                red: Int((red * 255).rounded()),
                green: Int((green * 255).rounded()),
                blue: Int((blue * 255).rounded())
            )
        } else {
            var white: CGFloat = 0
            uiColor.getWhite(&white, alpha: &alpha)
            let channel = Int((white * 255).rounded())
            self.init(red: channel, green: channel, blue: channel)
        }
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(MobileAppModel())
}
