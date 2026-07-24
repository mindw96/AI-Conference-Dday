package dev.mindw.dday

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import dev.mindw.dday.ui.DdayApp
import dev.mindw.dday.ui.theme.DdayTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            DdayTheme {
                DdayApp()
            }
        }
    }
}
