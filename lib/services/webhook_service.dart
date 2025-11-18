import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'preferences_service.dart';

class WebhookService {
  static final WebhookService instance = WebhookService._init();

  WebhookService._init();

  Future<bool> sendNotification(NotificationModel notification) async {
    try {
      final prefs = PreferencesService.instance;

      // Check if webhook is enabled
      if (!prefs.getWebhookEnabled()) {
        return false;
      }

      // Check if app is enabled for monitoring
      if (!prefs.isAppEnabled(notification.packageName)) {
        return false;
      }

      // Get app-specific webhook URL or fall back to global webhook URL
      final appConfigs = prefs.getAppConfigs();
      final appConfig = appConfigs.firstWhere(
        (c) => c.packageName == notification.packageName,
        orElse: () => null,
      );

      final webhookUrl = appConfig?.webhookUrl ?? prefs.getWebhookUrl();
      if (webhookUrl == null || webhookUrl.isEmpty) {
        return false;
      }

      // Prepare webhook payload
      final payload = {
        'type': 'notification',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'packageName': notification.packageName,
          'appName': notification.appName,
          'title': notification.title,
          'text': notification.text,
          'subText': notification.subText,
          'bigText': notification.bigText,
          'timestamp': notification.timestamp,
          'timestampISO': DateTime.fromMillisecondsSinceEpoch(notification.timestamp).toIso8601String(),
        }
      };

      // Get custom headers
      final headers = {
        'Content-Type': 'application/json',
        ...prefs.getWebhookHeaders(),
      };

      // Send POST request
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(
        const Duration(seconds: 10),
      );

      // Check response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Webhook sent successfully: ${response.statusCode}');
        return true;
      } else {
        print('Webhook failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Webhook error: $e');
      return false;
    }
  }

  Future<bool> testWebhook(String url, {Map<String, String>? headers}) async {
    try {
      final testPayload = {
        'type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
        'message': 'This is a test notification from Notifly',
      };

      final requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: requestHeaders,
        body: jsonEncode(testPayload),
      ).timeout(
        const Duration(seconds: 10),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Test webhook error: $e');
      return false;
    }
  }
}
