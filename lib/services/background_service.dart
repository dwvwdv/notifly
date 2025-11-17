import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  static final BackgroundService instance = BackgroundService._init();

  BackgroundService._init();

  void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notifly_foreground_service',
        channelName: 'Notifly Foreground Service',
        channelDescription: 'This notification appears when Notifly is monitoring notifications.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<bool> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Notifly is running',
      notificationText: 'Monitoring notifications in background',
      callback: startCallback,
    );

    return FlutterForegroundTask.isRunningService;
  }

  Future<bool> stopService() async {
    final result = await FlutterForegroundTask.stopService();
    return result.success;
  }

  Future<bool> isRunning() async {
    return FlutterForegroundTask.isRunningService;
  }

  Future<void> updateNotification({
    String? title,
    String? text,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: title ?? 'Notifly is running',
      notificationText: text ?? 'Monitoring notifications in background',
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(NotificationTaskHandler());
}

class NotificationTaskHandler extends TaskHandler {
  final int _notificationCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('Background service started');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // This is called periodically based on the interval
    // You can use this to perform periodic tasks

    // Send data to main isolate if needed
    final data = {
      'notificationCount': _notificationCount,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
    FlutterForegroundTask.sendDataToMain(data);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('Background service destroyed');
  }

  @override
  void onNotificationPressed() {
    // Handle notification press
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationButtonPressed(String id) {
    // Handle notification button presses
    print('Button pressed: $id');
  }
}
