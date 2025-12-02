import 'filter_condition.dart';

class AppConfig {
  final String packageName;
  final String appName;
  final bool isEnabled;
  final List<String> webhookUrls;
  final List<FilterRule> filterRules; // 進階過濾條件

  AppConfig({
    required this.packageName,
    required this.appName,
    required this.isEnabled,
    List<String>? webhookUrls,
    List<FilterRule>? filterRules,
  }) : webhookUrls = webhookUrls ?? [],
       filterRules = filterRules ?? [];

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isEnabled: json['isEnabled'] as bool,
      webhookUrls: json['webhookUrls'] != null
          ? List<String>.from(json['webhookUrls'] as List)
          : (json['webhookUrl'] != null ? [json['webhookUrl'] as String] : null),
      filterRules: json['filterRules'] != null
          ? (json['filterRules'] as List)
              .map((r) => FilterRule.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isEnabled': isEnabled,
      'webhookUrls': webhookUrls,
      'filterRules': filterRules.map((r) => r.toJson()).toList(),
    };
  }

  AppConfig copyWith({
    String? packageName,
    String? appName,
    bool? isEnabled,
    List<String>? webhookUrls,
    List<FilterRule>? filterRules,
  }) {
    return AppConfig(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isEnabled: isEnabled ?? this.isEnabled,
      webhookUrls: webhookUrls ?? this.webhookUrls,
      filterRules: filterRules ?? this.filterRules,
    );
  }
}
