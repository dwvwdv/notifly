/// 過濾條件模型
/// 用於定義 webhook 發送前的條件匹配
class FilterCondition {
  final String field; // 'title', 'text', 'appName', 'packageName', 'bigText', 'subText'
  final String operator; // 'contains', 'equals', 'startsWith', 'endsWith', 'matches', 'notContains', 'notEquals'
  final String value;

  FilterCondition({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory FilterCondition.fromJson(Map<String, dynamic> json) {
    return FilterCondition(
      field: json['field'] as String,
      operator: json['operator'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'operator': operator,
      'value': value,
    };
  }

  FilterCondition copyWith({
    String? field,
    String? operator,
    String? value,
  }) {
    return FilterCondition(
      field: field ?? this.field,
      operator: operator ?? this.operator,
      value: value ?? this.value,
    );
  }
}

/// Placeholder 提取器模型
/// 用於從通知內容中提取特定信息
class PlaceholderExtractor {
  final String name; // placeholder 名稱，如 'amount', 'currency'
  final String sourceField; // 'title', 'text', 'bigText', 'subText'
  final String pattern; // 正則表達式模式
  final int group; // 正則組索引（默認 1）

  PlaceholderExtractor({
    required this.name,
    required this.sourceField,
    required this.pattern,
    this.group = 1,
  });

  factory PlaceholderExtractor.fromJson(Map<String, dynamic> json) {
    return PlaceholderExtractor(
      name: json['name'] as String,
      sourceField: json['sourceField'] as String,
      pattern: json['pattern'] as String,
      group: json['group'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sourceField': sourceField,
      'pattern': pattern,
      'group': group,
    };
  }

  PlaceholderExtractor copyWith({
    String? name,
    String? sourceField,
    String? pattern,
    int? group,
  }) {
    return PlaceholderExtractor(
      name: name ?? this.name,
      sourceField: sourceField ?? this.sourceField,
      pattern: pattern ?? this.pattern,
      group: group ?? this.group,
    );
  }
}

/// 過濾規則模型
/// 包含多個條件和提取器
class FilterRule {
  final String id;
  final String name; // 規則名稱，如 "幣安儲值通知"
  final bool enabled;
  final List<FilterCondition> conditions; // 多個條件，全部滿足才匹配（AND 邏輯）
  final List<PlaceholderExtractor> extractors; // 提取器列表

  FilterRule({
    required this.id,
    required this.name,
    this.enabled = true,
    List<FilterCondition>? conditions,
    List<PlaceholderExtractor>? extractors,
  })  : conditions = conditions ?? [],
        extractors = extractors ?? [];

  factory FilterRule.fromJson(Map<String, dynamic> json) {
    return FilterRule(
      id: json['id'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool? ?? true,
      conditions: json['conditions'] != null
          ? (json['conditions'] as List)
              .map((c) => FilterCondition.fromJson(c))
              .toList()
          : null,
      extractors: json['extractors'] != null
          ? (json['extractors'] as List)
              .map((e) => PlaceholderExtractor.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'enabled': enabled,
      'conditions': conditions.map((c) => c.toJson()).toList(),
      'extractors': extractors.map((e) => e.toJson()).toList(),
    };
  }

  FilterRule copyWith({
    String? id,
    String? name,
    bool? enabled,
    List<FilterCondition>? conditions,
    List<PlaceholderExtractor>? extractors,
  }) {
    return FilterRule(
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
      conditions: conditions ?? this.conditions,
      extractors: extractors ?? this.extractors,
    );
  }
}
