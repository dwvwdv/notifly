import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/filter_condition.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

/// 過濾規則編輯器頁面（帶即時預覽）
class FilterRuleEditorPage extends StatefulWidget {
  final FilterRule rule;
  final String appName;
  final String packageName;
  final Function(FilterRule) onSave;

  const FilterRuleEditorPage({
    super.key,
    required this.rule,
    required this.appName,
    required this.packageName,
    required this.onSave,
  });

  @override
  State<FilterRuleEditorPage> createState() => _FilterRuleEditorPageState();
}

class _FilterRuleEditorPageState extends State<FilterRuleEditorPage> {
  late TextEditingController _nameController;
  late List<FilterCondition> _conditions;
  late List<PlaceholderExtractor> _extractors;

  List<NotificationModel> _recentNotifications = [];
  NotificationModel? _selectedNotification;
  bool _isLoadingNotifications = false;

  // 手動輸入模式
  bool _useManualInput = false;
  late TextEditingController _manualTitleController;
  late TextEditingController _manualTextController;
  late TextEditingController _manualBigTextController;
  late TextEditingController _manualSubTextController;

  final List<String> _fieldOptions = [
    'title',
    'text',
    'bigText',
    'subText',
    'appName',
    'packageName',
  ];

  final Map<String, String> _fieldLabels = {
    'title': '標題',
    'text': '內容',
    'bigText': '完整內容',
    'subText': '副標題',
    'appName': '應用名稱',
    'packageName': '包名',
  };

  final List<String> _operatorOptions = [
    'contains',
    'notContains',
    'equals',
    'notEquals',
    'startsWith',
    'endsWith',
    'matches',
  ];

  final Map<String, String> _operatorLabels = {
    'contains': '包含',
    'notContains': '不包含',
    'equals': '等於',
    'notEquals': '不等於',
    'startsWith': '開頭是',
    'endsWith': '結尾是',
    'matches': '匹配（正則）',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule.name);
    _conditions = List.from(widget.rule.conditions);
    _extractors = List.from(widget.rule.extractors);
    _manualTitleController = TextEditingController();
    _manualTextController = TextEditingController();
    _manualBigTextController = TextEditingController();
    _manualSubTextController = TextEditingController();
    _loadRecentNotifications();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _manualTitleController.dispose();
    _manualTextController.dispose();
    _manualBigTextController.dispose();
    _manualSubTextController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final notifications = await DatabaseService.instance.getNotificationsByPackage(
        widget.packageName,
        limit: 10,
      );
      setState(() {
        _recentNotifications = notifications;
        if (notifications.isNotEmpty) {
          _selectedNotification = notifications.first;
        }
      });
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  /// 獲取當前測試通知（從選中的通知或手動輸入）
  NotificationModel? _getTestNotification() {
    if (_useManualInput) {
      return NotificationModel(
        id: 0,
        appName: widget.appName,
        packageName: widget.packageName,
        title: _manualTitleController.text,
        text: _manualTextController.text,
        bigText: _manualBigTextController.text.isEmpty ? null : _manualBigTextController.text,
        subText: _manualSubTextController.text.isEmpty ? null : _manualSubTextController.text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      return _selectedNotification;
    }
  }

  void _saveRule() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入規則名稱')),
      );
      return;
    }

    final updatedRule = widget.rule.copyWith(
      name: _nameController.text.trim(),
      conditions: _conditions,
      extractors: _extractors,
    );

    widget.onSave(updatedRule);
    Navigator.pop(context);
  }

  void _addCondition() {
    showDialog(
      context: context,
      builder: (context) => _ConditionEditorDialog(
        onSave: (condition) {
          setState(() {
            _conditions.add(condition);
          });
        },
        fieldOptions: _fieldOptions,
        fieldLabels: _fieldLabels,
        operatorOptions: _operatorOptions,
        operatorLabels: _operatorLabels,
        testNotification: _getTestNotification(),
      ),
    );
  }

  void _editCondition(int index) {
    showDialog(
      context: context,
      builder: (context) => _ConditionEditorDialog(
        condition: _conditions[index],
        onSave: (condition) {
          setState(() {
            _conditions[index] = condition;
          });
        },
        fieldOptions: _fieldOptions,
        fieldLabels: _fieldLabels,
        operatorOptions: _operatorOptions,
        operatorLabels: _operatorLabels,
        testNotification: _getTestNotification(),
      ),
    );
  }

  void _deleteCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  void _addExtractor() {
    final testNotification = _getTestNotification();
    if (testNotification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇一條測試通知或輸入測試數據')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ExtractorEditorDialog(
        onSave: (extractor) {
          setState(() {
            _extractors.add(extractor);
          });
        },
        fieldOptions: _fieldOptions,
        fieldLabels: _fieldLabels,
        testNotification: testNotification,
      ),
    );
  }

  void _editExtractor(int index) {
    final testNotification = _getTestNotification();
    if (testNotification == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇一條測試通知或輸入測試數據')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ExtractorEditorDialog(
        extractor: _extractors[index],
        onSave: (extractor) {
          setState(() {
            _extractors[index] = extractor;
          });
        },
        fieldOptions: _fieldOptions,
        fieldLabels: _fieldLabels,
        testNotification: testNotification,
      ),
    );
  }

  void _deleteExtractor(int index) {
    setState(() {
      _extractors.removeAt(index);
    });
  }

  void _importFromRule() {
    showDialog(
      context: context,
      builder: (context) => _ImportConditionsDialog(
        onImport: (conditions, extractors) {
          setState(() {
            _conditions.addAll(conditions);
            _extractors.addAll(extractors);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已導入 ${conditions.length} 個條件和 ${extractors.length} 個提取器'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('編輯規則 - ${widget.appName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _importFromRule,
            tooltip: '導入條件',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRule,
            tooltip: '儲存',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 測試通知選擇器
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '測試通知',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (_isLoadingNotifications)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '選擇一條近期通知作為測試數據，用於預覽正則表達式的匹配效果',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // 手動輸入開關
                  Row(
                    children: [
                      const Text('手動輸入', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Switch(
                        value: _useManualInput,
                        onChanged: (value) {
                          setState(() {
                            _useManualInput = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_useManualInput) ...[
                    // 手動輸入表單
                    TextField(
                      controller: _manualTitleController,
                      decoration: const InputDecoration(
                        labelText: '標題',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualTextController,
                      decoration: const InputDecoration(
                        labelText: '內容',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualBigTextController,
                      decoration: const InputDecoration(
                        labelText: '完整內容（可選）',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _manualSubTextController,
                      decoration: const InputDecoration(
                        labelText: '副標題（可選）',
                        border: OutlineInputBorder(),
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ] else ...[
                    // 從現有通知選擇
                    if (_recentNotifications.isEmpty && !_isLoadingNotifications)
                      const Text(
                        '暫無近期通知記錄',
                        style: TextStyle(color: Colors.grey),
                      )
                    else if (_recentNotifications.isNotEmpty)
                      DropdownButtonFormField<NotificationModel>(
                        value: _selectedNotification,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        isExpanded: true,
                        menuMaxHeight: 400,
                        items: _recentNotifications.map((notification) {
                          return DropdownMenuItem(
                            value: notification,
                            child: Text(
                              notification.title.isEmpty ? '(無標題)' : notification.title,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedNotification = value;
                          });
                        },
                      ),
                      if (_selectedNotification != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '內容預覽',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedNotification!.text,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 規則名稱
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '規則名稱',
              hintText: '例如：幣安儲值通知',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 24),

          // 條件列表
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '匹配條件',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addCondition,
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '所有條件必須同時滿足（AND 邏輯）才會觸發此規則',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_conditions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('尚無條件，點擊上方「添加」按鈕新增'),
                ),
              ),
            )
          else
            ..._conditions.asMap().entries.map((entry) {
              final index = entry.key;
              final condition = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '${_fieldLabels[condition.field]} ${_operatorLabels[condition.operator]} "${condition.value}"',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editCondition(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteCondition(index),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // 提取器列表
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Placeholder 提取器',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _addExtractor,
                icon: const Icon(Icons.add),
                label: const Text('添加'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '從通知內容中提取特定資訊，結果會包含在 webhook payload 的 extractedFields 中',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (_extractors.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text('尚無提取器，點擊上方「添加」按鈕新增'),
                ),
              ),
            )
          else
            ..._extractors.asMap().entries.map((entry) {
              final index = entry.key;
              final extractor = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('提取 ${extractor.name}'),
                  subtitle: Text(
                    '從 ${_fieldLabels[extractor.sourceField]} 用正則 "${extractor.pattern}" 提取',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editExtractor(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteExtractor(index),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// 條件編輯對話框（帶測試通知預覽）
class _ConditionEditorDialog extends StatefulWidget {
  final FilterCondition? condition;
  final Function(FilterCondition) onSave;
  final List<String> fieldOptions;
  final Map<String, String> fieldLabels;
  final List<String> operatorOptions;
  final Map<String, String> operatorLabels;
  final NotificationModel? testNotification;

  const _ConditionEditorDialog({
    this.condition,
    required this.onSave,
    required this.fieldOptions,
    required this.fieldLabels,
    required this.operatorOptions,
    required this.operatorLabels,
    this.testNotification,
  });

  @override
  State<_ConditionEditorDialog> createState() => _ConditionEditorDialogState();
}

class _ConditionEditorDialogState extends State<_ConditionEditorDialog> {
  late String _selectedField;
  late String _selectedOperator;
  late TextEditingController _valueController;
  bool _testResult = false;

  @override
  void initState() {
    super.initState();
    _selectedField = widget.condition?.field ?? widget.fieldOptions.first;
    _selectedOperator = widget.condition?.operator ?? widget.operatorOptions.first;
    _valueController = TextEditingController(text: widget.condition?.value ?? '');
    _valueController.addListener(_testCondition);
    _testCondition();
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  String _getFieldValue(String field) {
    if (widget.testNotification == null) return '';
    switch (field) {
      case 'title':
        return widget.testNotification!.title;
      case 'text':
        return widget.testNotification!.text;
      case 'bigText':
        return widget.testNotification!.bigText ?? '';
      case 'subText':
        return widget.testNotification!.subText ?? '';
      case 'appName':
        return widget.testNotification!.appName;
      case 'packageName':
        return widget.testNotification!.packageName;
      default:
        return '';
    }
  }

  void _testCondition() {
    if (widget.testNotification == null || _valueController.text.isEmpty) {
      setState(() => _testResult = false);
      return;
    }

    final fieldValue = _getFieldValue(_selectedField);
    final testValue = _valueController.text;

    bool matches = false;
    try {
      switch (_selectedOperator) {
        case 'contains':
          matches = fieldValue.contains(testValue);
          break;
        case 'notContains':
          matches = !fieldValue.contains(testValue);
          break;
        case 'equals':
          matches = fieldValue == testValue;
          break;
        case 'notEquals':
          matches = fieldValue != testValue;
          break;
        case 'startsWith':
          matches = fieldValue.startsWith(testValue);
          break;
        case 'endsWith':
          matches = fieldValue.endsWith(testValue);
          break;
        case 'matches':
          matches = RegExp(testValue).hasMatch(fieldValue);
          break;
      }
    } catch (e) {
      matches = false;
    }

    setState(() => _testResult = matches);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.condition == null ? '添加條件' : '編輯條件'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 測試通知預覽
            if (widget.testNotification != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult ? Colors.green.shade50 : Colors.grey.shade100,
                  border: Border.all(
                    color: _testResult ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _testResult ? Icons.check_circle : Icons.cancel,
                          color: _testResult ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _testResult ? '✓ 條件匹配' : '✗ 條件不匹配',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _testResult ? Colors.green.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '測試值: ${_getFieldValue(_selectedField)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Text('字段', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedField,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.fieldOptions.map((field) {
                return DropdownMenuItem(
                  value: field,
                  child: Text(widget.fieldLabels[field] ?? field),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedField = value;
                    _testCondition();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('運算符', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedOperator,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: widget.operatorOptions.map((op) {
                return DropdownMenuItem(
                  value: op,
                  child: Text(widget.operatorLabels[op] ?? op),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedOperator = value;
                    _testCondition();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('值', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: _selectedOperator == 'matches' ? '正則表達式' : '匹配的值',
              ),
              maxLines: _selectedOperator == 'matches' ? 3 : 1,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_valueController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('請輸入值')),
              );
              return;
            }

            final condition = FilterCondition(
              field: _selectedField,
              operator: _selectedOperator,
              value: _valueController.text.trim(),
            );

            widget.onSave(condition);
            Navigator.pop(context);
          },
          child: const Text('確定'),
        ),
      ],
    );
  }
}

/// 提取器編輯對話框（帶即時預覽）
class _ExtractorEditorDialog extends StatefulWidget {
  final PlaceholderExtractor? extractor;
  final Function(PlaceholderExtractor) onSave;
  final List<String> fieldOptions;
  final Map<String, String> fieldLabels;
  final NotificationModel testNotification;

  const _ExtractorEditorDialog({
    this.extractor,
    required this.onSave,
    required this.fieldOptions,
    required this.fieldLabels,
    required this.testNotification,
  });

  @override
  State<_ExtractorEditorDialog> createState() => _ExtractorEditorDialogState();
}

class _ExtractorEditorDialogState extends State<_ExtractorEditorDialog> {
  late TextEditingController _nameController;
  late String _selectedField;
  late TextEditingController _patternController;
  late TextEditingController _groupController;

  String? _extractedValue;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.extractor?.name ?? '');
    _selectedField = widget.extractor?.sourceField ?? widget.fieldOptions.first;
    _patternController = TextEditingController(text: widget.extractor?.pattern ?? '');
    _groupController = TextEditingController(text: '${widget.extractor?.group ?? 1}');

    _patternController.addListener(_testExtraction);
    _groupController.addListener(_testExtraction);
    _testExtraction();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _patternController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  String _getFieldValue(String field) {
    switch (field) {
      case 'title':
        return widget.testNotification.title;
      case 'text':
        return widget.testNotification.text;
      case 'bigText':
        return widget.testNotification.bigText ?? '';
      case 'subText':
        return widget.testNotification.subText ?? '';
      case 'appName':
        return widget.testNotification.appName;
      case 'packageName':
        return widget.testNotification.packageName;
      default:
        return '';
    }
  }

  void _testExtraction() {
    final pattern = _patternController.text.trim();
    if (pattern.isEmpty) {
      setState(() {
        _extractedValue = null;
        _errorMessage = null;
      });
      return;
    }

    try {
      final fieldValue = _getFieldValue(_selectedField);
      final regex = RegExp(pattern);
      final match = regex.firstMatch(fieldValue);

      if (match != null) {
        final groupIndex = int.tryParse(_groupController.text.trim()) ?? 1;
        final safeGroupIndex = groupIndex.clamp(0, match.groupCount);

        setState(() {
          _extractedValue = match.group(safeGroupIndex);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _extractedValue = null;
          _errorMessage = '無匹配結果';
        });
      }
    } catch (e) {
      setState(() {
        _extractedValue = null;
        _errorMessage = '正則表達式錯誤: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldValue = _getFieldValue(_selectedField);

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 標題欄
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.extractor == null ? '添加提取器' : '編輯提取器',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 固定在頂部的即時預覽區域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _extractedValue != null ? Colors.green.shade50 : Colors.grey.shade100,
              border: Border.all(
                color: _extractedValue != null ? Colors.green : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _extractedValue != null ? Icons.check_circle : Icons.info,
                      color: _extractedValue != null ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '即時預覽',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _extractedValue != null ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  '測試文本:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: const BoxConstraints(maxHeight: 60),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      fieldValue.isEmpty ? '(空)' : fieldValue,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_extractedValue != null) ...[
                  Text(
                    '✓ 提取結果:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _extractedValue!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (_errorMessage != null) ...[
                  Text(
                    '✗ $_errorMessage',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 可滾動的表單區域
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('名稱', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例如：amount、currency',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('來源字段', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedField,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: widget.fieldOptions.map((field) {
                      return DropdownMenuItem(
                        value: field,
                        child: Text(widget.fieldLabels[field] ?? field),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedField = value;
                          _testExtraction();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('正則表達式', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _patternController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: r'例如：(\d+\.?\d*)(USDT|BTC)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '使用括號 () 來捕獲想提取的內容',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text('捕獲組索引', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _groupController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '1',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '0 = 整個匹配，1 = 第一個括號，2 = 第二個括號...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 底部按鈕
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請輸入名稱')),
                      );
                      return;
                    }

                    if (_patternController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('請輸入正則表達式')),
                      );
                      return;
                    }

                    final group = int.tryParse(_groupController.text.trim()) ?? 1;

                    final extractor = PlaceholderExtractor(
                      name: _nameController.text.trim(),
                      sourceField: _selectedField,
                      pattern: _patternController.text.trim(),
                      group: group,
                    );

                    widget.onSave(extractor);
                    Navigator.pop(context);
                  },
                  child: const Text('確定'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 導入條件和提取器對話框
class _ImportConditionsDialog extends StatefulWidget {
  final Function(List<FilterCondition>, List<PlaceholderExtractor>) onImport;

  const _ImportConditionsDialog({
    required this.onImport,
  });

  @override
  State<_ImportConditionsDialog> createState() => _ImportConditionsDialogState();
}

class _ImportConditionsDialogState extends State<_ImportConditionsDialog> {
  final TextEditingController _jsonController = TextEditingController();
  String? _errorMessage;
  FilterRule? _previewRule;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null && clipboardData.text != null) {
        setState(() {
          _jsonController.text = clipboardData.text!;
          _validateJson();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '無法從剪貼板粘貼: $e';
      });
    }
  }

  void _validateJson() {
    setState(() {
      _errorMessage = null;
      _previewRule = null;
    });

    final jsonText = _jsonController.text.trim();
    if (jsonText.isEmpty) {
      return;
    }

    try {
      final jsonData = jsonDecode(jsonText);
      final rule = FilterRule.fromJson(jsonData as Map<String, dynamic>);
      setState(() {
        _previewRule = rule;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '無效的 JSON 格式: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('導入條件和提取器'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '從已匯出的規則中導入條件和提取器：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '粘貼規則 JSON...',
                ),
                maxLines: 6,
                onChanged: (_) => _validateJson(),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste, size: 18),
                label: const Text('從剪貼板粘貼'),
              ),
              const SizedBox(height: 16),

              // 預覽區域
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_previewRule != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '將導入自「${_previewRule!.name}」',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('條件數: ${_previewRule!.conditions.length}'),
                      Text('提取器數: ${_previewRule!.extractors.length}'),
                      if (_previewRule!.conditions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '條件:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        ..._previewRule!.conditions.take(3).map((c) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                '• ${c.field} ${c.operator} "${c.value}"',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                        if (_previewRule!.conditions.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(
                              '...及 ${_previewRule!.conditions.length - 3} 個其他條件',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                      if (_previewRule!.extractors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '提取器:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        ..._previewRule!.extractors.take(3).map((e) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                '• ${e.name} (${e.sourceField})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                        if (_previewRule!.extractors.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(
                              '...及 ${_previewRule!.extractors.length - 3} 個其他提取器',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _previewRule != null
              ? () {
                  widget.onImport(
                    _previewRule!.conditions,
                    _previewRule!.extractors,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('導入'),
        ),
      ],
    );
  }
}
