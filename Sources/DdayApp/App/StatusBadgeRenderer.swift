import AppKit
import DdayCore

struct StatusBadgeEnvironment: Equatable {
    let isDark: Bool
    let reduceTransparency: Bool
    let increaseContrast: Bool

    @MainActor
    static func current(appearance: NSAppearance) -> Self {
        Self(
            isDark: appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua,
            reduceTransparency: NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency,
            increaseContrast: NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        )
    }
}

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
        glassAppearance: MenuBarGlassAppearance = .standard,
        environment: StatusBadgeEnvironment
    ) -> NSImage {
        let background = backgroundColor(
            for: style, glassAppearance: glassAppearance, environment: environment
        )
        let attributes = textAttributes(
            for: style,
            glassAppearance: glassAppearance,
            background: background,
            environment: environment
        )
        let textSize = text.size(withAttributes: attributes)
        let imageWidth = ceil(textSize.width + horizontalPadding * 2)
        let imageSize = NSSize(width: imageWidth, height: imageHeight)
        let badgeRect = NSRect(
            x: 0,
            y: (imageHeight - badgeHeight) / 2,
            width: imageWidth,
            height: badgeHeight
        )
        let textRect = NSRect(
            x: horizontalPadding,
            y: floor((imageHeight - textSize.height) / 2) + 1,
            width: textSize.width,
            height: textSize.height
        )

        let radius = cornerRadius
        let highlight = style == .glass && !environment.increaseContrast
        // AppKit redraws this representation at the destination display scale.
        // Capture resolved drawing values, not AppKit controls or app state:
        // the drawing handler can also be invoked off the main thread.
        let image = NSImage(size: imageSize, flipped: false) { _ in
            let path = NSBezierPath(roundedRect: badgeRect, xRadius: radius, yRadius: radius)
            background.setFill()
            path.fill()
            if highlight {
                let outline = NSBezierPath(
                    roundedRect: badgeRect.insetBy(dx: 0.5, dy: 0.5),
                    xRadius: radius - 0.5,
                    yRadius: radius - 0.5
                )
                outline.lineWidth = 0.8
                NSColor.white.withAlphaComponent(0.52).setStroke()
                outline.stroke()
            }
            text.draw(in: textRect, withAttributes: attributes)
            return true
        }
        image.isTemplate = false
        return image
    }

    private func textAttributes(
        for style: MenuBarVisualStyle,
        glassAppearance: MenuBarGlassAppearance,
        background: NSColor,
        environment: StatusBadgeEnvironment
    ) -> [NSAttributedString.Key: Any] {
        let color: NSColor
        switch style {
        case .plain:
            color = environment.isDark ? .white : .black
        case .badge:
            color = environment.increaseContrast ? .black : NSColor(calibratedWhite: 0.34, alpha: 1)
        case .glass:
            color = glassAppearance.usesAutomaticTextColor || environment.increaseContrast
                ? automaticTextColor(for: background, environment: environment)
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
        glassAppearance: MenuBarGlassAppearance,
        environment: StatusBadgeEnvironment
    ) -> NSColor {
        switch style {
        case .plain:
            return .clear
        case .badge:
            return NSColor(calibratedWhite: 0.93, alpha: environment.reduceTransparency || environment.increaseContrast ? 1 : 0.96)
        case .glass:
            return nsColor(for: glassAppearance.backgroundRGB)
                .withAlphaComponent(
                    environment.reduceTransparency || environment.increaseContrast
                        ? 1 : (environment.isDark ? 0.46 : 0.32)
                )
        }
    }

    private func automaticTextColor(for background: NSColor, environment: StatusBadgeEnvironment) -> NSColor {
        let color = background.usingColorSpace(.sRGB)!
        let base = environment.isDark ? 20.0 / 255 : 245.0 / 255
        let alpha = Double(color.alphaComponent)

        func linearized(_ component: Double) -> Double {
            let value = component * alpha + base * (1 - alpha)
            return value <= 0.04045
                ? value / 12.92
                : pow((value + 0.055) / 1.055, 2.4)
        }

        let luminance = 0.2126 * linearized(Double(color.redComponent))
            + 0.7152 * linearized(Double(color.greenComponent))
            + 0.0722 * linearized(Double(color.blueComponent))
        // Select the higher WCAG contrast ratio. In Increase Contrast mode
        // the opaque background makes this independent of the wallpaper.
        let blackContrast = (luminance + 0.05) / 0.05
        let whiteContrast = 1.05 / (luminance + 0.05)
        return blackContrast >= whiteContrast ? .black : .white
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
