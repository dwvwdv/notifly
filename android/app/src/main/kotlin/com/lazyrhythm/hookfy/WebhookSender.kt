package com.lazyrhythm.hookfy

import android.content.Context
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*
import kotlin.concurrent.thread

class WebhookSender(private val context: Context) {

    companion object {
        private const val TAG = "WebhookSender"
        private const val TIMEOUT_MS = 10000 // 10 seconds
    }

    /**
     * Send webhook for a notification
     * This runs in a background thread to avoid blocking the main thread
     */
    fun sendWebhook(
        notificationId: Long,
        packageName: String,
        appName: String,
        title: String,
        text: String,
        subText: String,
        bigText: String,
        timestamp: Long
    ) {
        thread {
            try {
                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences",
                    Context.MODE_PRIVATE
                )

                // Check if webhook is enabled
                val webhookEnabled = prefs.getBoolean("flutter.webhook_enabled", false)
                if (!webhookEnabled) {
                    Log.d(TAG, "Webhook disabled, skipping")
                    return@thread
                }

                // Get filter rules for this app
                val filterRules = getFilterRules(prefs, packageName)

                // Create notification data for matching
                val notificationData = NotificationData(
                    packageName = packageName,
                    appName = appName,
                    title = title,
                    text = text,
                    subText = subText,
                    bigText = bigText
                )

                // Check if notification matches filter rules
                val matchResult = FilterMatcher.matchNotification(notificationData, filterRules)

                if (!matchResult.matched) {
                    Log.d(TAG, "Notification did not match filter rules, skipping webhook")
                    // Update database status to "filtered" to indicate it was filtered out
                    val dbHelper = DatabaseHelper.getInstance(context)
                    dbHelper.updateWebhookStatus(notificationId, "filtered")
                    return@thread
                }

                // Get webhook URLs
                val webhookUrls = getWebhookUrls(prefs, packageName)
                if (webhookUrls.isEmpty()) {
                    Log.d(TAG, "No webhook URLs configured")
                    return@thread
                }

                // Get custom headers
                val headers = getWebhookHeaders(prefs)

                // Prepare payload with extracted fields
                val payload = createPayload(
                    packageName, appName, title, text, subText, bigText, timestamp,
                    matchResult.extractedFields
                )

                // Send to all webhook URLs
                var anySuccess = false
                for (url in webhookUrls) {
                    val success = sendToUrl(url, payload, headers)
                    if (success) {
                        anySuccess = true
                    }
                }

                // Update database status
                val dbHelper = DatabaseHelper.getInstance(context)
                val status = if (anySuccess) "success" else "failed"
                dbHelper.updateWebhookStatus(notificationId, status)

                // If failed, send failure notification
                if (!anySuccess) {
                    sendFailureNotification(notificationId, appName, title)
                }

                Log.d(TAG, "Webhook sent for notification $notificationId: $status")

            } catch (e: Exception) {
                Log.e(TAG, "Error sending webhook", e)

                // Update database to failed status
                try {
                    val dbHelper = DatabaseHelper.getInstance(context)
                    dbHelper.updateWebhookStatus(notificationId, "failed")
                    sendFailureNotification(notificationId, appName, title)
                } catch (ex: Exception) {
                    Log.e(TAG, "Error updating failed status", ex)
                }
            }
        }
    }

    /**
     * Get all webhook URLs for a package (app-specific + global)
     */
    private fun getWebhookUrls(prefs: android.content.SharedPreferences, packageName: String): List<String> {
        val urls = mutableSetOf<String>()

        // Get app-specific webhook URLs
        try {
            val appConfigsJson = prefs.getString("flutter.app_configs", null)
            if (appConfigsJson != null) {
                val appConfigsArray = JSONArray(appConfigsJson)
                for (i in 0 until appConfigsArray.length()) {
                    val config = appConfigsArray.getJSONObject(i)
                    if (config.getString("packageName") == packageName) {
                        val webhookUrlsArray = config.optJSONArray("webhookUrls")
                        if (webhookUrlsArray != null) {
                            for (j in 0 until webhookUrlsArray.length()) {
                                val url = webhookUrlsArray.getString(j)
                                if (url.isNotEmpty()) {
                                    urls.add(url)
                                }
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting app-specific webhook URLs", e)
        }

        // Get global webhook URL
        try {
            val globalUrl = prefs.getString("flutter.webhook_url", null)
            if (globalUrl != null && globalUrl.isNotEmpty()) {
                urls.add(globalUrl)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting global webhook URL", e)
        }

        return urls.toList()
    }

    /**
     * Get custom webhook headers
     */
    private fun getWebhookHeaders(prefs: android.content.SharedPreferences): Map<String, String> {
        return try {
            val headersJson = prefs.getString("flutter.webhook_headers", null)
            if (headersJson != null) {
                val jsonObject = JSONObject(headersJson)
                val headers = mutableMapOf<String, String>()
                val keys = jsonObject.keys()
                while (keys.hasNext()) {
                    val key = keys.next()
                    headers[key] = jsonObject.getString(key)
                }
                headers
            } else {
                emptyMap()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing webhook headers", e)
            emptyMap()
        }
    }

    /**
     * Get filter rules for a specific app
     */
    private fun getFilterRules(prefs: android.content.SharedPreferences, packageName: String): List<FilterRule> {
        return try {
            val appConfigsJson = prefs.getString("flutter.app_configs", null)
            if (appConfigsJson != null) {
                val appConfigsArray = JSONArray(appConfigsJson)
                for (i in 0 until appConfigsArray.length()) {
                    val config = appConfigsArray.getJSONObject(i)
                    if (config.getString("packageName") == packageName) {
                        val filterRulesArray = config.optJSONArray("filterRules")
                        if (filterRulesArray != null) {
                            return FilterMatcher.parseFilterRules(filterRulesArray)
                        }
                    }
                }
            }
            emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Error getting filter rules", e)
            emptyList()
        }
    }

    /**
     * Create webhook payload JSON with extracted fields
     */
    private fun createPayload(
        packageName: String,
        appName: String,
        title: String,
        text: String,
        subText: String,
        bigText: String,
        timestamp: Long,
        extractedFields: Map<String, String> = emptyMap()
    ): JSONObject {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
        dateFormat.timeZone = TimeZone.getTimeZone("UTC")

        return JSONObject().apply {
            put("type", "notification")
            put("timestamp", dateFormat.format(Date()))
            put("data", JSONObject().apply {
                put("packageName", packageName)
                put("appName", appName)
                put("title", title)
                put("text", text)
                put("subText", subText)
                put("bigText", bigText)
                put("timestamp", timestamp)
                put("timestampISO", dateFormat.format(Date(timestamp)))

                // Add extracted fields if any
                if (extractedFields.isNotEmpty()) {
                    put("extractedFields", JSONObject(extractedFields))
                }
            })
        }
    }

    /**
     * Send payload to a specific URL
     */
    private fun sendToUrl(urlString: String, payload: JSONObject, headers: Map<String, String>): Boolean {
        var connection: HttpURLConnection? = null
        try {
            val url = URL(urlString)
            connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.doOutput = true
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS

            // Set headers
            connection.setRequestProperty("Content-Type", "application/json")
            for ((key, value) in headers) {
                connection.setRequestProperty(key, value)
            }

            // Write payload
            val writer = OutputStreamWriter(connection.outputStream)
            writer.write(payload.toString())
            writer.flush()
            writer.close()

            // Check response
            val responseCode = connection.responseCode
            val success = responseCode in 200..299

            if (success) {
                Log.d(TAG, "Webhook sent successfully to $urlString: $responseCode")
            } else {
                Log.w(TAG, "Webhook failed for $urlString: $responseCode")
            }

            return success

        } catch (e: Exception) {
            Log.e(TAG, "Error sending webhook to $urlString", e)
            return false
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * Send failure notification to user
     */
    private fun sendFailureNotification(notificationId: Long, appName: String, title: String) {
        try {
            // This will be handled by MainActivity if the app is running
            // For now, just log it
            Log.w(TAG, "Webhook failed for notification $notificationId: $appName - $title")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending failure notification", e)
        }
    }
}
