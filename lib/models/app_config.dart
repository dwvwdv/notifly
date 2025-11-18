class AppConfig {
  final String packageName;
  final String appName;
  final bool isEnabled;
  final String? webhookUrl;

  AppConfig({
    required this.packageName,
    required this.appName,
    required this.isEnabled,
    this.webhookUrl,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isEnabled: json['isEnabled'] as bool,
      webhookUrl: json['webhookUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isEnabled': isEnabled,
      'webhookUrl': webhookUrl,
    };
  }

  AppConfig copyWith({
    String? packageName,
    String? appName,
    bool? isEnabled,
    String? webhookUrl,
  }) {
    return AppConfig(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isEnabled: isEnabled ?? this.isEnabled,
      webhookUrl: webhookUrl ?? this.webhookUrl,
    );
  }
}
