import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
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

  void _exportRule(int index) async {
    try {
      final rule = _filterRules[index];
      final jsonString = jsonEncode(rule.toJson());

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('規則「${rule.name}」已複製到剪貼板'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('匯出失敗: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _importRule() {
    showDialog(
      context: context,
      builder: (context) => _ImportRuleDialog(
        onImport: (rule) {
          setState(() {
            // 生成新的 ID 和調整名稱
            final newRule = rule.copyWith(
              id: const Uuid().v4(),
              name: '${rule.name} (導入)',
            );
            _filterRules.add(newRule);
            _saveChanges();
          });
        },
      ),
    );
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
                              } else if (value == 'export') {
                                _exportRule(index);
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
                                value: 'export',
                                child: Row(
                                  children: [
                                    Icon(Icons.upload, size: 20, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('匯出', style: TextStyle(color: Colors.blue)),
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _importRule,
            heroTag: 'import',
            tooltip: '導入規則',
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            onPressed: _addNewRule,
            heroTag: 'add',
            icon: const Icon(Icons.add),
            label: const Text('新增規則'),
          ),
        ],
      ),
    );
  }
}

/// 導入規則對話框
class _ImportRuleDialog extends StatefulWidget {
  final Function(FilterRule) onImport;

  const _ImportRuleDialog({
    required this.onImport,
  });

  @override
  State<_ImportRuleDialog> createState() => _ImportRuleDialogState();
}

class _ImportRuleDialogState extends State<_ImportRuleDialog> {
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
      title: const Text('導入規則'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '將匯出的規則 JSON 貼上到下方：',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _jsonController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '粘貼 JSON 字符串...',
                      ),
                      maxLines: 8,
                      onChanged: (_) => _validateJson(),
                    ),
                  ),
                ],
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
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '規則預覽',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Text('名稱: ${_previewRule!.name}'),
                      const SizedBox(height: 4),
                      Text('條件數: ${_previewRule!.conditions.length}'),
                      Text('提取器數: ${_previewRule!.extractors.length}'),
                      if (_previewRule!.conditions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '條件列表:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        ..._previewRule!.conditions.map((c) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                '• ${c.field} ${c.operator} "${c.value}"',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                      ],
                      if (_previewRule!.extractors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '提取器列表:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        ..._previewRule!.extractors.map((e) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Text(
                                '• ${e.name} (${e.sourceField})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
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
                  widget.onImport(_previewRule!);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已導入規則「${_previewRule!.name}」'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          child: const Text('導入'),
        ),
      ],
    );
  }
}
