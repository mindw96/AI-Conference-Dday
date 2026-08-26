import AppKit
import DdayCore

@MainActor
struct StatusBadgeRenderer {
    private let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
    private let horizontalPadding: CGFloat = 9
    private let imageHeight: CGFloat = 22
    private let badgeHeight: CGFloat = 20
    private let cornerRadius: CGFloat = 5

    func image(
        for text: String,
        style: MenuBarVisualStyle,
        glassAppearance: MenuBarGlassAppearance = .standard
    ) -> NSImage {
        let attributes = textAttributes(
            for: style,
            glassAppearance: glassAppearance
        )
        let textSize = text.size(withAttributes: attributes)
        let imageWidth = ceil(textSize.width + horizontalPadding * 2)
        let image = NSImage(size: NSSize(width: imageWidth, height: imageHeight))

        image.lockFocus()
        defer { image.unlockFocus() }

        let badgeRect = NSRect(
            x: 0,
            y: (imageHeight - badgeHeight) / 2,
            width: imageWidth,
            height: badgeHeight
        )
        let path = NSBezierPath(roundedRect: badgeRect, xRadius: cornerRadius, yRadius: cornerRadius)
        backgroundColor(
            for: style,
            glassAppearance: glassAppearance
        ).setFill()
        path.fill()

        if style == .glass {
            let highlightPath = NSBezierPath(
                roundedRect: badgeRect.insetBy(dx: 0.5, dy: 0.5),
                xRadius: cornerRadius - 0.5,
                yRadius: cornerRadius - 0.5
            )
            highlightPath.lineWidth = 0.8
            NSColor.white.withAlphaComponent(0.52).setStroke()
            highlightPath.stroke()
        }

        let textRect = NSRect(
            x: horizontalPadding,
            y: floor((imageHeight - textSize.height) / 2) + 1,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: attributes)

        image.isTemplate = false
        return image
    }

    private func textAttributes(
        for style: MenuBarVisualStyle,
        glassAppearance: MenuBarGlassAppearance
    ) -> [NSAttributedString.Key: Any] {
        let color: NSColor
        switch style {
        case .plain:
            color = .black
        case .badge:
            color = NSColor(calibratedWhite: 0.34, alpha: 1)
        case .glass:
            color = glassAppearance.usesAutomaticTextColor
                ? automaticTextColor(for: glassAppearance.backgroundRGB)
                : nsColor(for: glassAppearance.textRGB)
        }

        return [
            .font: font,
            .foregroundColor: color,
            .kern: 0
        ]
    }

    private func backgroundColor(
        for style: MenuBarVisualStyle,
        glassAppearance: MenuBarGlassAppearance
    ) -> NSColor {
        switch style {
        case .plain:
            return .clear
        case .badge:
            return NSColor(calibratedWhite: 0.93, alpha: 0.96)
        case .glass:
            return nsColor(for: glassAppearance.backgroundRGB)
                .withAlphaComponent(glassTintAlpha)
        }
    }

    private func automaticTextColor(for background: DdayRGBColor) -> NSColor {
        effectiveLuminance(of: background) > 0.48
            ? NSColor(calibratedWhite: 0.12, alpha: 0.96)
            : NSColor.white.withAlphaComponent(0.96)
    }

    private var glassTintAlpha: CGFloat {
        isDarkAppearance ? 0.46 : 0.32
    }

    private var isDarkAppearance: Bool {
        let appearance = NSApp?.effectiveAppearance ?? NSAppearance.currentDrawing()
        return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }

    private func effectiveLuminance(of color: DdayRGBColor) -> Double {
        let base = isDarkAppearance ? 20.0 : 245.0
        let alpha = Double(glassTintAlpha)

        func linearized(_ component: Double) -> Double {
            let composited = component * alpha + base * (1 - alpha)
            let value = composited / 255
            return value <= 0.04045
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * linearized(Double(color.red))
            + 0.7152 * linearized(Double(color.green))
            + 0.0722 * linearized(Double(color.blue))
    }

    private func nsColor(for color: DdayRGBColor) -> NSColor {
        NSColor(
            srgbRed: CGFloat(color.red) / 255,
            green: CGFloat(color.green) / 255,
            blue: CGFloat(color.blue) / 255,
            alpha: 1
        )
    }
}
