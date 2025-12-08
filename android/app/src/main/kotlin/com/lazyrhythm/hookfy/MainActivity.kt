package com.lazyrhythm.hookfy

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.*
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lazyrhythm.hookfy/notification"
    private val EVENT_CHANNEL = "com.lazyrhythm.hookfy/notification_stream"
    private val WEBHOOK_FAILURE_CHANNEL_ID = "webhook_failure"
    private val WEBHOOK_FAILURE_CHANNEL_NAME = "Webhook Failures"

    private var notificationReceiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Create notification channel for webhook failures
        createNotificationChannel()

        // Method Channel for checking permissions and opening settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    val hasPermission = isNotificationServiceEnabled()
                    result.success(hasPermission)
                }
                "openNotificationSettings" -> {
                    openNotificationListenerSettings()
                    result.success(null)
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "sendWebhookFailureNotification" -> {
                    val notificationId = call.argument<Int>("notificationId")
                    val appName = call.argument<String>("appName")
                    val title = call.argument<String>("title")

                    if (notificationId != null && appName != null && title != null) {
                        sendWebhookFailureNotification(notificationId, appName, title)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                    }
                }
                "getSensitiveNotificationStatus" -> {
                    val status = getSensitiveNotificationStatus()
                    result.success(status)
                }
                "getPackageName" -> {
                    result.success(packageName)
                }
                else -> result.notImplemented()
            }
        }

        // Event Channel for notification stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerNotificationReceiver()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    unregisterNotificationReceiver()
                }
            }
        )
    }

    private fun registerNotificationReceiver() {
        notificationReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val notificationData = intent?.getStringExtra(NotificationListener.EXTRA_NOTIFICATION_DATA)
                eventSink?.success(notificationData)
            }
        }

        val filter = IntentFilter(NotificationListener.ACTION_NOTIFICATION_RECEIVED)
        registerReceiver(notificationReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
    }

    private fun unregisterNotificationReceiver() {
        notificationReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Receiver already unregistered
            }
        }
        notificationReceiver = null
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (!flat.isNullOrEmpty()) {
            val names = flat.split(":")
            for (name in names) {
                val componentName = ComponentName.unflattenFromString(name)
                if (componentName != null && componentName.packageName == packageName) {
                    return true
                }
            }
        }
        return false
    }

    private fun openNotificationListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val apps = pm.getInstalledApplications(android.content.pm.PackageManager.GET_META_DATA)
        val appList = mutableListOf<Map<String, String>>()

        for (app in apps) {
            try {
                val packageName = app.packageName
                val appName = pm.getApplicationLabel(app).toString()

                // Include app if it has a launcher intent (user-visible apps)
                // This includes both system apps with UI (Phone, Messages) and user-installed apps (LINE, Gotify)
                val launchIntent = pm.getLaunchIntentForPackage(packageName)
                if (launchIntent != null) {
                    appList.add(mapOf(
                        "appName" to appName,
                        "packageName" to packageName
                    ))
                }
            } catch (e: Exception) {
                // Skip apps that throw exceptions
            }
        }

        return appList.sortedBy { it["appName"] }
    }

    override fun onDestroy() {
        unregisterNotificationReceiver()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(
                WEBHOOK_FAILURE_CHANNEL_ID,
                WEBHOOK_FAILURE_CHANNEL_NAME,
                importance
            ).apply {
                description = "Notifications for webhook delivery failures"
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun sendWebhookFailureNotification(notificationId: Int, appName: String, title: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("retry_notification_id", notificationId)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, WEBHOOK_FAILURE_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("Webhook 發送失敗")
            .setContentText("來自 $appName: $title")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("來自 $appName 的通知「$title」webhook 發送失敗，點擊查看詳情"))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notification)
    }

    /**
     * Get status information about sensitive notification access
     * Returns a map with:
     * - androidVersion: Current Android SDK version
     * - hasRestriction: Whether device has sensitive notification restrictions (Android 15+)
     * - canAccessSensitive: Whether app can access sensitive notifications (best effort check)
     */
    private fun getSensitiveNotificationStatus(): Map<String, Any> {
        val androidVersion = Build.VERSION.SDK_INT
        val hasRestriction = androidVersion >= 35 // Android 15 (API 35)

        // Check if we have RECEIVE_SENSITIVE_NOTIFICATIONS permission
        // This is a best-effort check as the permission is difficult to query directly
        var canAccessSensitive = false

        if (hasRestriction) {
            try {
                // Try to check the permission using AppOpsManager
                val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
                val mode = appOps.unsafeCheckOpNoThrow(
                    "android:receive_sensitive_notifications",
                    android.os.Process.myUid(),
                    packageName
                )
                canAccessSensitive = (mode == android.app.AppOpsManager.MODE_ALLOWED)
            } catch (e: Exception) {
                // If we can't check, assume we don't have it
                canAccessSensitive = false
            }
        } else {
            // On Android 14 and below, there's no restriction
            canAccessSensitive = true
        }

        return mapOf(
            "androidVersion" to androidVersion,
            "hasRestriction" to hasRestriction,
            "canAccessSensitive" to canAccessSensitive
        )
    }
}
