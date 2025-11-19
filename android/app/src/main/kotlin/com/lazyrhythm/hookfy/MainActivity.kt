package com.lazyrhythm.hookfy

import android.content.*
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lazyrhythm.hookfy/notification"
    private val EVENT_CHANNEL = "com.lazyrhythm.hookfy/notification_stream"

    private var notificationReceiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
}
