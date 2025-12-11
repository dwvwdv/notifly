import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';
import '../providers/app_config_provider.dart';
import 'app_selection_page.dart';
import 'sensitive_notification_guide_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _webhookUrlController = TextEditingController();
  bool _isTestingWebhook = false;

  // Sensitive notification status
  int _androidVersion = 0;
  bool _hasRestriction = false;
  bool _canAccessSensitive = false;
  String _packageName = '';
  bool _isLoadingSensitiveStatus = true;

  static const platform = MethodChannel('com.lazyrhythm.hookfy/notification');

  @override
  void initState() {
    super.initState();
    _loadWebhookUrl();
    _loadSensitiveNotificationStatus();
  }

  Future<void> _loadSensitiveNotificationStatus() async {
    try {
      setState(() {
        _isLoadingSensitiveStatus = true;
      });

      final status = await platform.invokeMethod<Map>('getSensitiveNotificationStatus');
      final packageName = await platform.invokeMethod<String>('getPackageName');

      if (status != null && mounted) {
        setState(() {
          _androidVersion = status['androidVersion'] as int;
          _hasRestriction = status['hasRestriction'] as bool;
          _canAccessSensitive = status['canAccessSensitive'] as bool;
          _packageName = packageName ?? '';
          _isLoadingSensitiveStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSensitiveStatus = false;
        });
      }
    }
  }

  Future<void> _loadWebhookUrl() async {
    final settingsProvider = context.read<SettingsProvider>();
    _webhookUrlController.text = settingsProvider.webhookUrl;
  }

  @override
  void dispose() {
    _webhookUrlController.dispose();
    super.dispose();
  }

  void _showWebhookInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Webhook 執行邏輯'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hookfy 支援兩種 webhook 配置方式：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. 全局 Webhook URL'),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '• 在此頁面配置\n'
                  '• 適用於所有啟用的應用\n'
                  '• 所有通知都會發送到此 URL',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(height: 12),
              Text('2. 應用特定 Webhook URLs'),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '• 在「選擇應用」頁面為每個應用單獨配置\n'
                  '• 可為特定應用設置多個 webhook URLs\n'
                  '• 支援條件式路由',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '發送規則：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '• 如果應用配置了特定 URLs，會發送到這些 URLs\n'
                  '• 如果配置了全局 URL，也會發送到全局 URL\n'
                  '• 兩者可以同時發送（重複的 URL 會自動去除）\n'
                  '• 如果都沒有配置，則不發送',
                  style: TextStyle(fontSize: 13),
                ),
              ),
              SizedBox(height: 12),
              Text(
                '範例：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '• 只配置全局 URL：所有應用都發送到全局 URL\n'
                  '• 只配置特定 URLs：只有配置的應用發送到其 URLs\n'
                  '• 兩者都配置：發送到全局 URL + 應用特定 URLs',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRescanAppsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新掃描應用'),
        content: const Text('是否重新掃描以同步當前裝置 app 數量？\n\n這將檢測新安裝的應用程式。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('掃描'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final appConfigProvider = context.read<AppConfigProvider>();
      await appConfigProvider.loadInstalledApps();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('掃描完成！目前共 ${appConfigProvider.appConfigs.length} 個應用'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _testWebhook() async {
    if (_webhookUrlController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入 Webhook URL')),
      );
      return;
    }

    setState(() {
      _isTestingWebhook = true;
    });

    // Get provider reference before async operations
    final settingsProvider = context.read<SettingsProvider>();

    try {
      // Save the URL first
      await settingsProvider.setWebhookUrl(_webhookUrlController.text.trim());

      final success = await settingsProvider.testWebhook();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Webhook 測試成功！' : 'Webhook 測試失敗'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingWebhook = false;
        });
      }
    }
  }

  Widget _buildSensitiveNotificationSection() {
    if (_isLoadingSensitiveStatus) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // For Android 14 and below, show a simple info message
    if (!_hasRestriction) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '無限制',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Android $_androidVersion 版本無敏感通知存取限制',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // For Android 15+, show detailed status
    return Column(
      children: [
        // Status card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _canAccessSensitive ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _canAccessSensitive ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _canAccessSensitive ? Icons.check_circle : Icons.warning_amber,
                      color: _canAccessSensitive ? Colors.green.shade700 : Colors.orange.shade700,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _canAccessSensitive ? '已授權' : '受限',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _canAccessSensitive
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Android $_androidVersion',
                            style: TextStyle(
                              fontSize: 13,
                              color: _canAccessSensitive
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: _canAccessSensitive
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      onPressed: _loadSensitiveNotificationStatus,
                      tooltip: '重新檢測',
                    ),
                  ],
                ),
                if (!_canAccessSensitive) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ 受影響的通知類型：',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('2FA 驗證碼通知', Colors.orange),
                  _buildBulletPoint('簡訊驗證碼', Colors.orange),
                  _buildBulletPoint('銀行驗證通知', Colors.orange),
                  const SizedBox(height: 12),
                  Text(
                    '這些通知會顯示為「sensitive notification content hidden」，無法接收完整內容。',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Solution button
        if (!_canAccessSensitive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SensitiveNotificationGuidePage(
                        packageName: _packageName,
                      ),
                    ),
                  ).then((_) {
                    // Refresh status when returning from guide page
                    _loadSensitiveNotificationStatus();
                  });
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('查看解決方案'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        // Info section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _canAccessSensitive
                        ? 'Hookfy 已獲得敏感通知存取權限，可以接收所有類型的通知。'
                        : 'Android 15 為保護用戶安全，自動隱藏包含驗證碼等敏感信息的通知內容。點擊上方按鈕查看解決方案。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 14, color: color.shade700),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final appConfigProvider = context.watch<AppConfigProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Webhook 配置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Enable Webhook'),
            subtitle: const Text('啟用 webhook 通知發送'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showWebhookInfoDialog,
                  tooltip: '查看 webhook 執行邏輯',
                ),
                Switch(
                  value: settingsProvider.webhookEnabled,
                  onChanged: (value) {
                    settingsProvider.toggleWebhook(value);
                  },
                ),
              ],
            ),
          ),
          if (settingsProvider.webhookEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '全局 Webhook URL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _webhookUrlController,
                    decoration: const InputDecoration(
                      hintText: 'https://your-server.com/webhook',
                      border: OutlineInputBorder(),
                      helperText: '此 URL 會接收所有啟用應用的通知',
                    ),
                    onChanged: (value) {
                      // Auto-save on change
                      settingsProvider.setWebhookUrl(value.trim());
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isTestingWebhook ? null : _testWebhook,
                        icon: _isTestingWebhook
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isTestingWebhook ? '測試中...' : '測試 Webhook'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
          ],
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'App Monitoring',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: const Text('Select Apps'),
            subtitle: Text('${appConfigProvider.enabledAppCount} apps enabled'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppSelectionPage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Rescan Apps'),
            subtitle: const Text('同步當前裝置的應用程式列表'),
            leading: const Icon(Icons.refresh),
            trailing: appConfigProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: appConfigProvider.isLoading ? null : _showRescanAppsDialog,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '通知列表',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('滑動刪除通知'),
            subtitle: const Text('左右滑動可刪除通知紀錄'),
            value: settingsProvider.swipeToDeleteEnabled,
            onChanged: (value) {
              settingsProvider.toggleSwipeToDelete(value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Background Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Run in Background'),
            subtitle: const Text('Keep monitoring when app is closed'),
            value: settingsProvider.backgroundServiceEnabled,
            onChanged: (value) {
              settingsProvider.toggleBackgroundService(value);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '敏感通知存取',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSensitiveNotificationSection(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.2.0+8'),
          ),
          const ListTile(
            title: Text('Description'),
            subtitle: Text(
              'Hookfy monitors Android notifications and sends them to your webhook endpoint.',
            ),
          ),
        ],
      ),
    );
  }
}
