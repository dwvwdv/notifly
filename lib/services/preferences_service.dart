import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  SharedPreferences? _prefs;

  PreferencesService._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Webhook URL
  Future<void> setWebhookUrl(String url) async {
    await prefs.setString('webhook_url', url);
  }

  String? getWebhookUrl() {
    return prefs.getString('webhook_url');
  }

  // Webhook enabled
  Future<void> setWebhookEnabled(bool enabled) async {
    await prefs.setBool('webhook_enabled', enabled);
  }

  bool getWebhookEnabled() {
    return prefs.getBool('webhook_enabled') ?? false;
  }

  // Monitor all apps
  Future<void> setMonitorAllApps(bool monitorAll) async {
    await prefs.setBool('monitor_all_apps', monitorAll);
  }

  bool getMonitorAllApps() {
    return prefs.getBool('monitor_all_apps') ?? true;
  }

  // App configs
  Future<void> saveAppConfigs(List<AppConfig> configs) async {
    final jsonList = configs.map((config) => config.toJson()).toList();
    await prefs.setString('app_configs', jsonEncode(jsonList));
  }

  List<AppConfig> getAppConfigs() {
    final jsonString = prefs.getString('app_configs');
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => AppConfig.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateAppConfig(AppConfig config) async {
    final configs = getAppConfigs();
    final index = configs.indexWhere(
      (c) => c.packageName == config.packageName,
    );

    if (index != -1) {
      configs[index] = config;
    } else {
      configs.add(config);
    }

    await saveAppConfigs(configs);
  }

  /// Check if an app is enabled for monitoring
  /// Logic:
  /// 1. If app has specific config in app_configs, use that config's isEnabled value
  /// 2. If no specific config, fallback to monitor_all_apps setting
  bool isAppEnabled(String packageName) {
    final configs = getAppConfigs();

    // Try to find specific config for this app
    try {
      final config = configs.firstWhere(
        (c) => c.packageName == packageName,
      );
      // Found specific config, use its isEnabled value
      return config.isEnabled;
    } catch (e) {
      // No specific config found, fallback to monitor_all_apps
      return getMonitorAllApps();
    }
  }

  // Background service
  Future<void> setBackgroundServiceEnabled(bool enabled) async {
    await prefs.setBool('background_service_enabled', enabled);
  }

  bool getBackgroundServiceEnabled() {
    return prefs.getBool('background_service_enabled') ?? true;
  }

  // Webhook headers (optional custom headers)
  Future<void> setWebhookHeaders(Map<String, String> headers) async {
    await prefs.setString('webhook_headers', jsonEncode(headers));
  }

  Map<String, String> getWebhookHeaders() {
    final jsonString = prefs.getString('webhook_headers');
    if (jsonString == null) return {};

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return json.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    await prefs.clear();
  }
}
