import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';
import '../services/background_service.dart';
import '../services/webhook_service.dart';

class SettingsProvider extends ChangeNotifier {
  String _webhookUrl = '';
  bool _webhookEnabled = false;
  bool _backgroundServiceEnabled = true;
  Map<String, String> _webhookHeaders = {};
  bool _swipeToDeleteEnabled = true;

  String get webhookUrl => _webhookUrl;
  bool get webhookEnabled => _webhookEnabled;
  bool get backgroundServiceEnabled => _backgroundServiceEnabled;
  Map<String, String> get webhookHeaders => _webhookHeaders;
  bool get swipeToDeleteEnabled => _swipeToDeleteEnabled;

  Future<void> init() async {
    await loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = PreferencesService.instance;
    _webhookUrl = prefs.getWebhookUrl() ?? '';
    _webhookEnabled = prefs.getWebhookEnabled();
    _backgroundServiceEnabled = prefs.getBackgroundServiceEnabled();
    _webhookHeaders = prefs.getWebhookHeaders();
    _swipeToDeleteEnabled = prefs.getSwipeToDeleteEnabled();
    notifyListeners();
  }

  Future<void> setWebhookUrl(String url) async {
    _webhookUrl = url;
    await PreferencesService.instance.setWebhookUrl(url);
    notifyListeners();
  }

  Future<void> toggleWebhook(bool enabled) async {
    _webhookEnabled = enabled;
    await PreferencesService.instance.setWebhookEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleBackgroundService(bool enabled) async {
    _backgroundServiceEnabled = enabled;
    await PreferencesService.instance.setBackgroundServiceEnabled(enabled);

    if (enabled) {
      await BackgroundService.instance.startService();
    } else {
      await BackgroundService.instance.stopService();
    }

    notifyListeners();
  }

  Future<void> setWebhookHeaders(Map<String, String> headers) async {
    _webhookHeaders = headers;
    await PreferencesService.instance.setWebhookHeaders(headers);
    notifyListeners();
  }

  Future<bool> testWebhook() async {
    if (_webhookUrl.isEmpty) return false;

    return await WebhookService.instance.testWebhook(
      _webhookUrl,
      headers: _webhookHeaders,
    );
  }

  Future<void> toggleSwipeToDelete(bool enabled) async {
    _swipeToDeleteEnabled = enabled;
    await PreferencesService.instance.setSwipeToDeleteEnabled(enabled);
    notifyListeners();
  }
}
