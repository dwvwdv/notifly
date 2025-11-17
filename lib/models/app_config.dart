class AppConfig {
  final String packageName;
  final String appName;
  final bool isEnabled;

  AppConfig({
    required this.packageName,
    required this.appName,
    required this.isEnabled,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      isEnabled: json['isEnabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isEnabled': isEnabled,
    };
  }

  AppConfig copyWith({
    String? packageName,
    String? appName,
    bool? isEnabled,
  }) {
    return AppConfig(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
