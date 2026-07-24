package dev.mindw.dday.data

import android.content.Context
import dev.mindw.dday.model.Conference
import dev.mindw.dday.model.ConferenceDeadline
import dev.mindw.dday.model.ConferenceSubcategory
import dev.mindw.dday.model.DeadlineKind
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL

class ConferenceRepository(context: Context) {
    private val appContext = context.applicationContext
    private val cacheFile = File(appContext.filesDir, CACHE_FILENAME)

    suspend fun load(): List<Conference> = withContext(Dispatchers.IO) {
        val bundled = appContext.assets.open(ASSET_FILENAME)
            .bufferedReader()
            .use { it.readText() }
        val cached = cacheFile.takeIf(File::isFile)?.readText()

        cached
            ?.let { runCatching { parse(it) }.getOrNull() }
            ?: parse(bundled)
    }

    suspend fun refresh(): List<Conference> = withContext(Dispatchers.IO) {
        val url = URL(DATA_URL)
        require(url.protocol == "https") { "Conference data must use HTTPS." }

        val connection = (url.openConnection() as HttpURLConnection).apply {
            connectTimeout = 15_000
            readTimeout = 30_000
            instanceFollowRedirects = true
            useCaches = false
            setRequestProperty("Accept", "application/json")
        }

        try {
            connection.connect()
            require(connection.responseCode in 200..299) {
                "Server returned HTTP ${connection.responseCode}."
            }

            val declaredLength = connection.contentLengthLong
            require(declaredLength <= MAX_DOWNLOAD_BYTES || declaredLength < 0) {
                "Conference data is larger than 5 MB."
            }

            val bytes = connection.inputStream.use(::readLimited)
            val text = bytes.toString(Charsets.UTF_8)
            val parsed = parse(text)
            cacheFile.writeText(text)
            parsed
        } finally {
            connection.disconnect()
        }
    }

    private fun parse(text: String): List<Conference> {
        val array = JSONArray(text)
        return buildList(array.length()) {
            for (index in 0 until array.length()) {
                add(parseConference(array.getJSONObject(index)))
            }
        }
    }

    private fun parseConference(json: JSONObject): Conference {
        val deadlines = json.getJSONArray("deadlines")
        return Conference(
            id = json.getString("id"),
            name = json.getString("name"),
            fullName = json.getString("fullName"),
            year = json.getInt("year"),
            fields = json.getJSONArray("field").toStringList(),
            subcategory = ConferenceSubcategory.fromRawValue(json.getString("subcategory")),
            location = json.getString("location"),
            websiteUrl = json.getString("websiteUrl").validatedWebUrl(),
            sourceUrl = json.getString("sourceUrl").validatedWebUrl(),
            sourceCheckedAt = json.getString("sourceCheckedAt"),
            timezone = json.getString("timezone"),
            deadlines = buildList(deadlines.length()) {
                for (index in 0 until deadlines.length()) {
                    add(parseDeadline(deadlines.getJSONObject(index)))
                }
            },
        )
    }

    private fun parseDeadline(json: JSONObject): ConferenceDeadline =
        ConferenceDeadline(
            id = json.getString("id"),
            label = json.getString("label"),
            date = json.getString("date"),
            time = json.optString("time").takeIf { it.isNotBlank() && it != "null" },
            timezone = json.getString("timezone"),
            type = DeadlineKind.fromRawValue(json.getString("type")),
            isPrimary = json.optBoolean("isPrimary", false),
        )

    private fun readLimited(input: java.io.InputStream): ByteArray {
        val output = ByteArrayOutputStream()
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
        var total = 0

        while (true) {
            val count = input.read(buffer)
            if (count < 0) {
                break
            }
            total += count
            require(total <= MAX_DOWNLOAD_BYTES) {
                "Conference data is larger than 5 MB."
            }
            output.write(buffer, 0, count)
        }

        return output.toByteArray()
    }

    private fun JSONArray.toStringList(): List<String> =
        buildList(length()) {
            for (index in 0 until length()) {
                add(getString(index))
            }
        }

    private fun String.validatedWebUrl(): String {
        val uri = URI(this)
        require(uri.scheme == "https" || uri.scheme == "http") {
            "Unsupported URL scheme."
        }
        return this
    }

    private companion object {
        const val ASSET_FILENAME = "conferences.json"
        const val CACHE_FILENAME = "conferences.json"
        const val MAX_DOWNLOAD_BYTES = 5 * 1024 * 1024
        const val DATA_URL =
            "https://raw.githubusercontent.com/mindw96/AI-Conference-Dday/main/data/conferences.json"
    }
}
