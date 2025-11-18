import 'package:flutter/foundation.dart';
import '../models/app_config.dart';
import '../services/preferences_service.dart';
import '../services/notification_service.dart';

class AppConfigProvider extends ChangeNotifier {
  List<AppConfig> _appConfigs = [];
  bool _monitorAllApps = true;
  bool _isLoading = false;

  List<AppConfig> get appConfigs => _appConfigs;
  bool get monitorAllApps => _monitorAllApps;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await loadConfigs();
    await loadInstalledApps();
  }

  Future<void> loadConfigs() async {
    _isLoading = true;
    notifyListeners();

    final prefs = PreferencesService.instance;
    _appConfigs = prefs.getAppConfigs();
    _monitorAllApps = prefs.getMonitorAllApps();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadInstalledApps() async {
    _isLoading = true;
    notifyListeners();

    try {
      final installedApps = await NotificationService.instance.getInstalledApps();
      final existingPackages = _appConfigs.map((c) => c.packageName).toSet();

      // Add new apps to the list
      for (var app in installedApps) {
        final packageName = app['packageName']!;
        final appName = app['appName']!;

        if (!existingPackages.contains(packageName)) {
          _appConfigs.add(AppConfig(
            packageName: packageName,
            appName: appName,
            isEnabled: _monitorAllApps,
          ));
        }
      }

      // Sort by app name
      _appConfigs.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

      await _saveConfigs();
    } catch (e) {
      print('Error loading installed apps: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleMonitorAllApps(bool value) async {
    _monitorAllApps = value;

    // Update all app configs
    if (value) {
      _appConfigs = _appConfigs.map((config) => config.copyWith(isEnabled: true)).toList();
    }

    await PreferencesService.instance.setMonitorAllApps(value);
    await _saveConfigs();
    notifyListeners();
  }

  Future<void> toggleApp(String packageName, bool enabled) async {
    final index = _appConfigs.indexWhere((c) => c.packageName == packageName);
    if (index != -1) {
      _appConfigs[index] = _appConfigs[index].copyWith(isEnabled: enabled);
      await _saveConfigs();
      notifyListeners();
    }
  }

  Future<void> updateAppWebhook(String packageName, String? webhookUrl) async {
    final index = _appConfigs.indexWhere((c) => c.packageName == packageName);
    if (index != -1) {
      _appConfigs[index] = _appConfigs[index].copyWith(webhookUrl: webhookUrl);
      await _saveConfigs();
      notifyListeners();
    }
  }

  Future<void> _saveConfigs() async {
    await PreferencesService.instance.saveAppConfigs(_appConfigs);
  }

  List<AppConfig> get enabledApps => _appConfigs.where((c) => c.isEnabled).toList();

  int get enabledAppCount => _monitorAllApps ? _appConfigs.length : enabledApps.length;
}
