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
    );
  }
}
