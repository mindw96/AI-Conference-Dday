// Appended to the renderer by check_macos_menu.sh. Preferences are injected;
// these checks never change the user's system accessibility settings.
extension StatusBadgeRenderer {
    static func runAccessibilityChecks() -> Int32 {
        let renderer = Self()
        var failures: Int32 = 0
        var count = 0
        func check(_ condition: Bool, _ name: String) {
            count += 1
            if !condition { failures += 1 }
            print("\(condition ? "PASS" : "FAIL"): \(name)")
        }
        func luminance(_ color: NSColor) -> Double {
            let rgb = color.usingColorSpace(.sRGB)!
            let channels = [rgb.redComponent, rgb.greenComponent, rgb.blueComponent].map {
                let c = Double($0)
                return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return zip(channels, [0.2126, 0.7152, 0.0722]).map(*).reduce(0, +)
        }
        for isDark in [false, true] {
            let accessible = StatusBadgeEnvironment(isDark: isDark, reduceTransparency: false, increaseContrast: true)
            var minimumContrast = Double.infinity
            var allOpaque = true
            for red in [0, 85, 170, 255] {
                for green in [0, 85, 170, 255] {
                    for blue in [0, 85, 170, 255] {
                        let rgb = DdayRGBColor(red: red, green: green, blue: blue)
                        let custom = MenuBarGlassAppearance(backgroundRGB: rgb, textRGB: rgb, usesAutomaticTextColor: false)
                        let background = renderer.backgroundColor(for: .glass, glassAppearance: custom, environment: accessible)
                        let foreground = renderer.textAttributes(for: .glass, glassAppearance: custom, background: background, environment: accessible)[.foregroundColor] as! NSColor
                        let values = [luminance(background), luminance(foreground)].sorted()
                        minimumContrast = min(minimumContrast, (values[1] + 0.05) / (values[0] + 0.05))
                        allOpaque = allOpaque && background.alphaComponent == 1
                    }
                }
            }
            check(minimumContrast >= 4.5, "Increase Contrast meets 4.5:1 for 64 custom colors (dark=\(isDark))")
            check(allOpaque, "Increase Contrast removes wallpaper-dependent transparency (dark=\(isDark))")

            let reduced = StatusBadgeEnvironment(isDark: isDark, reduceTransparency: true, increaseContrast: false)
            let opaque = renderer.backgroundColor(for: .glass, glassAppearance: .standard, environment: reduced)
            check(opaque.alphaComponent == 1, "Reduce Transparency makes the glass badge opaque (dark=\(isDark))")
            let normal = StatusBadgeEnvironment(isDark: isDark, reduceTransparency: false, increaseContrast: false)
            let translucent = renderer.backgroundColor(for: .glass, glassAppearance: .standard, environment: normal)
            check(translucent.alphaComponent < 1, "Normal appearance preserves the translucent badge (dark=\(isDark))")

            let image = renderer.image(for: "D-27", style: .glass, environment: reduced)
            let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: Int(ceil(image.size.width * 2)), pixelsHigh: 44,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
            )!
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            image.draw(in: NSRect(x: 0, y: 0, width: bitmap.pixelsWide, height: bitmap.pixelsHigh))
            NSGraphicsContext.restoreGraphicsState()
            check((bitmap.colorAt(x: 8, y: 22)?.alphaComponent ?? 0) > 0.99, "2x badge drawing preserves opaque accessible fill (dark=\(isDark))")
        }
        print("\(count - Int(failures))/\(count) macOS badge accessibility checks passed")
        print("DDAY_MACOS_BADGE_CHECKS_COMPLETED")
        return failures == 0 ? 0 : 1
    }
}
