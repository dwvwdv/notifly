package com.example.notifly

import android.app.Notification
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        const val ACTION_NOTIFICATION_RECEIVED = "com.example.notifly.NOTIFICATION_RECEIVED"
        const val EXTRA_NOTIFICATION_DATA = "notification_data"
    }

    /**
     * Check if an app is enabled for monitoring based on SharedPreferences
     * Logic:
     * 1. Check if app has specific config in app_configs - use that config
     * 2. If no specific config, fallback to monitor_all_apps setting
     */
    private fun isAppEnabled(packageName: String): Boolean {
        try {
            val prefs = applicationContext.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )

            // First, check if there's an app-specific config
            val appConfigsJson = prefs.getString("flutter.app_configs", null)

            if (appConfigsJson != null) {
                val appConfigsArray = JSONArray(appConfigsJson)

                // Look for this specific app's configuration
                for (i in 0 until appConfigsArray.length()) {
                    val config = appConfigsArray.getJSONObject(i)
                    if (config.getString("packageName") == packageName) {
                        val isEnabled = config.getBoolean("isEnabled")
                        Log.d(TAG, "App $packageName has specific config - isEnabled: $isEnabled")
                        return isEnabled
                    }
                }
            }

            // No specific config found, fallback to monitor_all_apps setting
            val monitorAllApps = prefs.getBoolean("flutter.monitor_all_apps", true)
            Log.d(TAG, "App $packageName not in config - using monitor_all_apps: $monitorAllApps")
            return monitorAllApps

        } catch (e: Exception) {
            Log.e(TAG, "Error checking if app is enabled: $e", e)
            // Default to true to avoid blocking notifications on errors
            return true
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        try {
            val packageName = sbn.packageName
            val notification = sbn.notification

            // Skip our own notifications
            if (packageName == applicationContext.packageName) {
                return
            }

            // Check if this app is enabled for monitoring
            if (!isAppEnabled(packageName)) {
                Log.d(TAG, "Notification from $packageName skipped - app monitoring disabled")
                return
            }

            // Extract notification data
            val extras = notification.extras
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: text

            // Get app name
            val appName = try {
                val pm = packageManager
                val appInfo = pm.getApplicationInfo(packageName, 0)
                pm.getApplicationLabel(appInfo).toString()
            } catch (e: Exception) {
                packageName
            }

            // Save to database directly
            // This ensures notifications are saved even when the app is not running
            val dbHelper = DatabaseHelper.getInstance(applicationContext)
            dbHelper.insertNotification(
                packageName = packageName,
                appName = appName,
                title = title,
                text = text,
                subText = subText,
                bigText = bigText,
                timestamp = sbn.postTime,
                key = sbn.key
            )

            // Create notification data JSON
            val notificationData = JSONObject().apply {
                put("id", sbn.id)
                put("packageName", packageName)
                put("appName", appName)
                put("title", title)
                put("text", text)
                put("subText", subText)
                put("bigText", bigText)
                put("timestamp", sbn.postTime)
                put("key", sbn.key)
            }

            Log.d(TAG, "Notification received and saved: $notificationData")

            // Broadcast to Flutter app for real-time UI updates
            // This will only work when the app is running, but that's OK
            // because the notification is already saved to the database
            val intent = Intent(ACTION_NOTIFICATION_RECEIVED).apply {
                putExtra(EXTRA_NOTIFICATION_DATA, notificationData.toString())
            }
            sendBroadcast(intent)

        } catch (e: Exception) {
            Log.e(TAG, "Error processing notification", e)
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
        Log.d(TAG, "Notification removed: ${sbn.packageName}")
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification Listener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification Listener disconnected")

        // Try to reconnect
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            requestRebind(android.content.ComponentName(this, NotificationListener::class.java))
        }
    }
}
