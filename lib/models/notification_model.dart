class NotificationModel {
  final int? id;
  final String packageName;
  final String appName;
  final String title;
  final String text;
  final String? subText;
  final String? bigText;
  final int timestamp;
  final String? key;
  final String? webhookStatus; // null = not sent, 'success', 'failed', 'retried_success'

  NotificationModel({
    this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.text,
    this.subText,
    this.bigText,
    required this.timestamp,
    this.key,
    this.webhookStatus,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int?,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      subText: json['subText'] as String?,
      bigText: json['bigText'] as String?,
      timestamp: json['timestamp'] as int,
      key: json['key'] as String?,
      webhookStatus: json['webhookStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'title': title,
      'text': text,
      'subText': subText,
      'bigText': bigText,
      'timestamp': timestamp,
      'key': key,
      'webhookStatus': webhookStatus,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'package_name': packageName,
      'app_name': appName,
      'title': title,
      'text': text,
      'sub_text': subText,
      'big_text': bigText,
      'timestamp': timestamp,
      'key': key,
      'webhook_status': webhookStatus,
    };
  }

  factory NotificationModel.fromDatabase(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      title: map['title'] as String,
      text: map['text'] as String,
      subText: map['sub_text'] as String?,
      bigText: map['big_text'] as String?,
      timestamp: map['timestamp'] as int,
      key: map['key'] as String?,
      webhookStatus: map['webhook_status'] as String?,
    );
  }

  // Helper method to copy with new webhook status
  NotificationModel copyWith({
    int? id,
    String? packageName,
    String? appName,
    String? title,
    String? text,
    String? subText,
    String? bigText,
    int? timestamp,
    String? key,
    String? webhookStatus,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      text: text ?? this.text,
      subText: subText ?? this.subText,
      bigText: bigText ?? this.bigText,
      timestamp: timestamp ?? this.timestamp,
      key: key ?? this.key,
      webhookStatus: webhookStatus ?? this.webhookStatus,
    );
  }
}
