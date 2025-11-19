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

      // Get app-specific webhook URLs
      final appConfigs = prefs.getAppConfigs();
      final matchingConfigs = appConfigs.where(
        (c) => c.packageName == notification.packageName,
      );
      final appConfig = matchingConfigs.isNotEmpty ? matchingConfigs.first : null;

      // Collect all webhook URLs to send to
      List<String> webhookUrls = [];

      // Add app-specific webhook URLs
      if (appConfig?.webhookUrls != null && appConfig!.webhookUrls.isNotEmpty) {
        webhookUrls.addAll(appConfig.webhookUrls);
      }

      // Add global webhook URL if configured
      final globalWebhookUrl = prefs.getWebhookUrl();
      if (globalWebhookUrl != null && globalWebhookUrl.isNotEmpty) {
        webhookUrls.add(globalWebhookUrl);
      }

      // Remove duplicates and empty URLs
      webhookUrls = webhookUrls.where((url) => url.isNotEmpty).toSet().toList();

      if (webhookUrls.isEmpty) {
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

      // Send POST requests to all webhook URLs
      final results = await Future.wait(
        webhookUrls.map((url) async {
          try {
            final response = await http.post(
              Uri.parse(url),
              headers: headers,
              body: jsonEncode(payload),
            ).timeout(
              const Duration(seconds: 10),
            );

            if (response.statusCode >= 200 && response.statusCode < 300) {
              print('Webhook sent successfully to $url: ${response.statusCode}');
              return true;
            } else {
              print('Webhook failed for $url: ${response.statusCode} - ${response.body}');
              return false;
            }
          } catch (e) {
            print('Webhook error for $url: $e');
            return false;
          }
        }),
      );

      // Return true if at least one webhook succeeded
      return results.any((result) => result);
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
        'message': 'This is a test notification from Hookfy',
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
