import AppKit
import DdayCore

@MainActor
final class BadgeAppearanceWindowController: NSWindowController, NSTextFieldDelegate {
    private let strings: BadgeAppearanceStrings
    private let onChange: (MenuBarGlassAppearance) -> Void
    private var appearance: MenuBarGlassAppearance

    private let badgeRenderer = StatusBadgeRenderer()
    private let previewImageView = NSImageView()
    private let backgroundColorWell = NSColorWell()
    private let textColorWell = NSColorWell()
    private let automaticTextCheckbox = NSButton()
    private var backgroundFields: [NSTextField] = []
    private var textFields: [NSTextField] = []

    init(
        appearance: MenuBarGlassAppearance,
        language: AppLanguage,
        onChange: @escaping (MenuBarGlassAppearance) -> Void
    ) {
        self.appearance = appearance
        self.strings = BadgeAppearanceStrings(language: language)
        self.onChange = onChange

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 430),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        super.init(window: window)

        configureWindow()
        configureContent()
        synchronizeControls()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        guard let window else {
            return
        }

        showWindow(nil)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow() {
        guard let window else {
            return
        }

        window.title = strings.windowTitle
        window.isReleasedWhenClosed = false
        window.animationBehavior = .utilityWindow
        window.tabbingMode = .disallowed
    }

    private func configureContent() {
        guard let window else {
            return
        }

        let contentView = NSView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let titleLabel = label(
            strings.title,
            font: .systemFont(ofSize: 18, weight: .semibold)
        )
        let descriptionLabel = label(
            strings.description,
            font: .systemFont(ofSize: 12),
            color: .secondaryLabelColor
        )
        descriptionLabel.maximumNumberOfLines = 2
        descriptionLabel.lineBreakMode = .byWordWrapping

        let previewLabel = label(
            strings.preview,
            font: .systemFont(ofSize: 12, weight: .semibold),
            color: .secondaryLabelColor
        )
        let preview = makePreviewView()

        let backgroundEditor = makeColorEditor(
            title: strings.background,
            colorWell: backgroundColorWell,
            tagOffset: 0,
            storage: &backgroundFields
        )
        let textEditor = makeColorEditor(
            title: strings.text,
            colorWell: textColorWell,
            tagOffset: 10,
            storage: &textFields
        )
        let sectionSeparator = separator()

        automaticTextCheckbox.setButtonType(.switch)
        automaticTextCheckbox.title = strings.automaticText
        automaticTextCheckbox.font = .systemFont(ofSize: 12)
        automaticTextCheckbox.target = self
        automaticTextCheckbox.action = #selector(automaticTextChanged(_:))

        let resetButton = NSButton(
            title: strings.reset,
            target: self,
            action: #selector(resetAppearance)
        )
        resetButton.bezelStyle = .rounded

        let doneButton = NSButton(
            title: strings.done,
            target: self,
            action: #selector(closeWindow)
        )
        doneButton.bezelStyle = .rounded
        doneButton.keyEquivalent = "\r"

        let buttonSpacer = NSView()
        buttonSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let buttonRow = NSStackView(views: [resetButton, buttonSpacer, doneButton])
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = 10

        let stack = NSStackView(views: [
            titleLabel,
            descriptionLabel,
            previewLabel,
            preview,
            backgroundEditor,
            sectionSeparator,
            textEditor,
            automaticTextCheckbox,
            buttonRow
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            preview.widthAnchor.constraint(equalTo: stack.widthAnchor),
            backgroundEditor.widthAnchor.constraint(equalTo: stack.widthAnchor),
            sectionSeparator.widthAnchor.constraint(equalTo: stack.widthAnchor),
            textEditor.widthAnchor.constraint(equalTo: stack.widthAnchor),
            buttonRow.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func makePreviewView() -> NSView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.material = .contentBackground
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 8

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.imageAlignment = .alignCenter
        previewImageView.imageScaling = .scaleNone
        visualEffectView.addSubview(previewImageView)

        NSLayoutConstraint.activate([
            visualEffectView.heightAnchor.constraint(equalToConstant: 70),
            previewImageView.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            previewImageView.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor)
        ])

        return visualEffectView
    }

    private func makeColorEditor(
        title: String,
        colorWell: NSColorWell,
        tagOffset: Int,
        storage: inout [NSTextField]
    ) -> NSView {
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.isContinuous = true
        colorWell.target = self
        colorWell.action = tagOffset == 0
            ? #selector(backgroundColorChanged(_:))
            : #selector(textColorChanged(_:))
        NSLayoutConstraint.activate([
            colorWell.widthAnchor.constraint(equalToConstant: 48),
            colorWell.heightAnchor.constraint(equalToConstant: 28)
        ])

        let sectionTitle = label(
            title,
            font: .systemFont(ofSize: 13, weight: .semibold)
        )
        let titleSpacer = NSView()
        titleSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let titleRow = NSStackView(views: [sectionTitle, titleSpacer, colorWell])
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 8

        let channelRow = NSStackView()
        channelRow.orientation = .horizontal
        channelRow.alignment = .centerY
        channelRow.spacing = 12

        for (index, channel) in ["R", "G", "B"].enumerated() {
            let field = makeChannelField(title: channel, tag: tagOffset + index)
            storage.append(field)
            channelRow.addArrangedSubview(channelPair(title: channel, field: field))
        }

        let section = NSStackView(views: [titleRow, channelRow])
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 8
        titleRow.widthAnchor.constraint(equalTo: section.widthAnchor).isActive = true
        return section
    }

    private func makeChannelField(title: String, tag: Int) -> NSTextField {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = 0
        formatter.maximum = 255
        formatter.allowsFloats = false

        let field = NSTextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.tag = tag
        field.alignment = .right
        field.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        field.formatter = formatter
        field.target = self
        field.action = #selector(channelFieldChanged(_:))
        field.delegate = self
        field.toolTip = "\(title): 0-255"
        field.widthAnchor.constraint(equalToConstant: 64).isActive = true
        return field
    }

    private func channelPair(title: String, field: NSTextField) -> NSView {
        let channelLabel = label(
            title,
            font: .monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            color: .secondaryLabelColor
        )
        let pair = NSStackView(views: [channelLabel, field])
        pair.orientation = .horizontal
        pair.alignment = .centerY
        pair.spacing = 6
        return pair
    }

    private func separator() -> NSView {
        let separator = NSBox()
        separator.boxType = .separator
        return separator
    }

    private func label(
        _ text: String,
        font: NSFont,
        color: NSColor = .labelColor
    ) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        return label
    }

    private func synchronizeControls() {
        backgroundColorWell.color = appearance.backgroundRGB.nsColor
        textColorWell.color = appearance.textRGB.nsColor
        setFields(backgroundFields, color: appearance.backgroundRGB)
        setFields(textFields, color: appearance.textRGB)
        automaticTextCheckbox.state = appearance.usesAutomaticTextColor ? .on : .off
        setCustomTextControlsEnabled(!appearance.usesAutomaticTextColor)
        updatePreview()
    }

    private func setFields(_ fields: [NSTextField], color: DdayRGBColor) {
        for (field, value) in zip(fields, [color.red, color.green, color.blue]) {
            field.integerValue = value
        }
    }

    private func setCustomTextControlsEnabled(_ isEnabled: Bool) {
        textColorWell.isEnabled = isEnabled
        textFields.forEach { $0.isEnabled = isEnabled }
    }

    private func updatePreview() {
        previewImageView.image = badgeRenderer.image(
            for: "AAAI D-42",
            style: .glass,
            glassAppearance: appearance
        )
    }

    private func commitAppearance() {
        updatePreview()
        onChange(appearance)
    }

    @objc private func backgroundColorChanged(_ sender: NSColorWell) {
        appearance.backgroundRGB = DdayRGBColor(nsColor: sender.color)
        setFields(backgroundFields, color: appearance.backgroundRGB)
        commitAppearance()
    }

    @objc private func textColorChanged(_ sender: NSColorWell) {
        appearance.textRGB = DdayRGBColor(nsColor: sender.color)
        setFields(textFields, color: appearance.textRGB)
        commitAppearance()
    }

    @objc private func channelFieldChanged(_ sender: NSTextField) {
        let value = min(max(sender.integerValue, 0), 255)
        sender.integerValue = value

        if sender.tag < 10 {
            appearance.backgroundRGB = appearance.backgroundRGB.replacing(
                channel: sender.tag,
                value: value
            )
            backgroundColorWell.color = appearance.backgroundRGB.nsColor
        } else {
            appearance.textRGB = appearance.textRGB.replacing(
                channel: sender.tag - 10,
                value: value
            )
            textColorWell.color = appearance.textRGB.nsColor
        }

        commitAppearance()
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let field = notification.object as? NSTextField else {
            return
        }
        channelFieldChanged(field)
    }

    @objc private func automaticTextChanged(_ sender: NSButton) {
        appearance.usesAutomaticTextColor = sender.state == .on
        setCustomTextControlsEnabled(!appearance.usesAutomaticTextColor)
        commitAppearance()
    }

    @objc private func resetAppearance() {
        appearance = .standard
        synchronizeControls()
        onChange(appearance)
    }

    @objc private func closeWindow() {
        window?.performClose(nil)
    }
}

private struct BadgeAppearanceStrings {
    let windowTitle: String
    let title: String
    let description: String
    let preview: String
    let background: String
    let text: String
    let automaticText: String
    let reset: String
    let done: String

    init(language: AppLanguage) {
        let usesKorean: Bool
        switch language {
        case .system:
            usesKorean = Locale.preferredLanguages.first?.hasPrefix("ko") == true
        case .english:
            usesKorean = false
        case .korean:
            usesKorean = true
        }

        if usesKorean {
            windowTitle = "Glass Badge 색상"
            title = "Glass Badge"
            description = "메뉴 막대 배지의 배경색과 글씨색을 RGB로 지정합니다. 변경 내용은 즉시 적용됩니다."
            preview = "실제 크기 미리보기"
            background = "배경색"
            text = "글씨색"
            automaticText = "배경에 따라 글씨색 자동 선택"
            reset = "기본값 복원"
            done = "완료"
        } else {
            windowTitle = "Glass Badge Colors"
            title = "Glass Badge"
            description = "Choose the menu bar badge background and text colors with RGB values. Changes apply immediately."
            preview = "Actual-size preview"
            background = "Background"
            text = "Text"
            automaticText = "Choose text color automatically for contrast"
            reset = "Restore Defaults"
            done = "Done"
        }
    }
}

private extension DdayRGBColor {
    init(nsColor: NSColor) {
        guard let color = nsColor.usingColorSpace(.sRGB) else {
            self = .standardFallback
            return
        }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(
            red: Int((red * 255).rounded()),
            green: Int((green * 255).rounded()),
            blue: Int((blue * 255).rounded())
        )
    }

    var nsColor: NSColor {
        NSColor(
            srgbRed: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: 1
        )
    }

    func replacing(channel: Int, value: Int) -> DdayRGBColor {
        switch channel {
        case 0:
            return DdayRGBColor(red: value, green: green, blue: blue)
        case 1:
            return DdayRGBColor(red: red, green: value, blue: blue)
        default:
            return DdayRGBColor(red: red, green: green, blue: value)
        }
    }

    static var standardFallback: DdayRGBColor {
        MenuBarGlassAppearance.standard.backgroundRGB
    }
}
