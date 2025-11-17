import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'preferences_service.dart';

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
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
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

    final serviceId = await FlutterForegroundTask.startService(
      notificationTitle: 'Notifly is running',
      notificationText: 'Monitoring notifications in background',
      callback: startCallback,
    );

    return serviceId != null;
  }

  Future<bool> stopService() async {
    return await FlutterForegroundTask.stopService();
  }

  Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
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
  int _notificationCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print('Background service started');
  }

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // This is called periodically based on the interval
    // You can use this to perform periodic tasks

    // Send data to main isolate if needed
    sendPort?.send(_notificationCount);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('Background service destroyed');
  }

  @override
  void onButtonPressed(String id) {
    // Handle notification button presses
    print('Button pressed: $id');
  }

  @override
  void onNotificationPressed() {
    // Handle notification press
    FlutterForegroundTask.launchApp('/');
  }
}
