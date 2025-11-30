import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/notification_model.dart';
import 'preferences_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  static const platform = MethodChannel('com.lazyrhythm.hookfy/notification');
  static const eventChannel = EventChannel('com.lazyrhythm.hookfy/notification_stream');

  final _notificationController = StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  StreamSubscription? _eventSubscription;

  NotificationService._init();

  Future<void> init() async {
    await _startListening();
  }

  Future<void> _startListening() async {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        try {
          if (event is String) {
            final Map<String, dynamic> data = jsonDecode(event);
            final notification = NotificationModel.fromJson(data);

            // Check if app is enabled for monitoring
            if (!PreferencesService.instance.isAppEnabled(notification.packageName)) {
              return;
            }

            // Note: Notification is already saved to database in native layer (NotificationListener.kt)
            // Webhook is also sent automatically in native layer (WebhookSender.kt)
            // Flutter layer only handles UI updates and manual retry

            // Notify listeners for UI updates
            _notificationController.add(notification);
          }
        } catch (e) {
          print('Error processing notification: $e');
        }
      },
      onError: (error) {
        print('Notification stream error: $error');
      },
    );
  }

  Future<bool> checkNotificationPermission() async {
    try {
      final bool hasPermission = await platform.invokeMethod('checkNotificationPermission');
      return hasPermission;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
    } catch (e) {
      print('Error opening notification settings: $e');
    }
  }

  Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic> apps = await platform.invokeMethod('getInstalledApps');
      return apps.map((app) => Map<String, String>.from(app)).toList();
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _notificationController.close();
  }
}
