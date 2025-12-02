import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/app_config.dart';
import '../models/filter_condition.dart';
import 'filter_rule_editor_page.dart';

/// 應用的進階過濾條件配置頁面
class AppFilterRulesPage extends StatefulWidget {
  final AppConfig appConfig;
  final Function(AppConfig) onUpdate;

  const AppFilterRulesPage({
    super.key,
    required this.appConfig,
    required this.onUpdate,
  });

  @override
  State<AppFilterRulesPage> createState() => _AppFilterRulesPageState();
}

class _AppFilterRulesPageState extends State<AppFilterRulesPage> {
  late List<FilterRule> _filterRules;

  @override
  void initState() {
    super.initState();
    _filterRules = List.from(widget.appConfig.filterRules);
  }

  void _addNewRule() {
    final newRule = FilterRule(
      id: const Uuid().v4(),
      name: '新規則 ${_filterRules.length + 1}',
      enabled: true,
      conditions: [],
      extractors: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterRuleEditorPage(
          rule: newRule,
          appName: widget.appConfig.appName,
          packageName: widget.appConfig.packageName,
          onSave: (updatedRule) {
            setState(() {
              _filterRules.add(updatedRule);
              _saveChanges();
            });
          },
        ),
      ),
    );
  }

  void _editRule(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterRuleEditorPage(
          rule: _filterRules[index],
          appName: widget.appConfig.appName,
          packageName: widget.appConfig.packageName,
          onSave: (updatedRule) {
            setState(() {
              _filterRules[index] = updatedRule;
              _saveChanges();
            });
          },
        ),
      ),
    );
  }

  void _deleteRule(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除規則'),
        content: Text('確定要刪除規則「${_filterRules[index].name}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterRules.removeAt(index);
                _saveChanges();
              });
              Navigator.pop(context);
            },
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleRuleEnabled(int index, bool value) {
    setState(() {
      _filterRules[index] = _filterRules[index].copyWith(enabled: value);
      _saveChanges();
    });
  }

  void _saveChanges() {
    final updatedConfig = widget.appConfig.copyWith(filterRules: _filterRules);
    widget.onUpdate(updatedConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.appConfig.appName} - 進階條件'),
      ),
      body: Column(
        children: [
          // 說明卡片
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '什麼是進階條件？',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '進階條件可讓您：\n'
                    '• 只在特定條件下發送 webhook（如標題包含特定文字）\n'
                    '• 從通知中提取資訊（如金額、貨幣等）\n'
                    '• 為不同類型的通知設定不同規則\n\n'
                    '如果未設定任何規則，所有通知都會發送。',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // 規則列表
          Expanded(
            child: _filterRules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '尚未設定過濾規則',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '點擊下方按鈕新增第一條規則',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filterRules.length,
                    itemBuilder: (context, index) {
                      final rule = _filterRules[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            rule.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('條件：${rule.conditions.length} 個'),
                              Text('提取器：${rule.extractors.length} 個'),
                            ],
                          ),
                          leading: Switch(
                            value: rule.enabled,
                            onChanged: (value) => _toggleRuleEnabled(index, value),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editRule(index);
                              } else if (value == 'delete') {
                                _deleteRule(index);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('編輯'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('刪除', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewRule,
        icon: const Icon(Icons.add),
        label: const Text('新增規則'),
      ),
    );
  }
}
