package dev.mindw.dday.model

import org.junit.Assert.assertEquals
import org.junit.Test

class WidgetAppearanceTest {
    @Test
    fun unknownAppearanceValuesUseSafeDefaults() {
        assertEquals(
            WidgetBackground.System,
            WidgetBackground.fromRawValue("future-background"),
        )
        assertEquals(
            WidgetTextColor.Auto,
            WidgetTextColor.fromRawValue("future-text-color"),
        )
    }
}
