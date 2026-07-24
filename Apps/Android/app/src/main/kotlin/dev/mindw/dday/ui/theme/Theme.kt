package dev.mindw.dday.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val LightColors = lightColorScheme(
    primary = Color(0xFF0A84FF),
    onPrimary = Color.White,
    background = Color(0xFFF2F2F7),
    onBackground = Color(0xFF111111),
    surface = Color.White,
    onSurface = Color(0xFF111111),
    surfaceVariant = Color(0xFFF2F2F7),
    onSurfaceVariant = Color(0xFF707078),
    outlineVariant = Color(0xFFE4E4E9),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF64A9FF),
    onPrimary = Color(0xFF001E36),
    background = Color(0xFF111318),
    onBackground = Color(0xFFF2F2F7),
    surface = Color(0xFF1C1C1E),
    onSurface = Color(0xFFF2F2F7),
    surfaceVariant = Color(0xFF2C2C2E),
    onSurfaceVariant = Color(0xFFB2B2B8),
    outlineVariant = Color(0xFF3A3A3C),
)

@Composable
fun DdayTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) DarkColors else LightColors,
        content = content,
    )
}
