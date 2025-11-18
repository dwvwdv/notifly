import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/app_config_provider.dart';
import 'app_selection_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _webhookUrlController = TextEditingController();
  bool _isTestingWebhook = false;

  @override
  void initState() {
    super.initState();
    _loadWebhookUrl();
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
                'Notifly 支援兩種 webhook 配置方式：',
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
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('Description'),
            subtitle: Text(
              'Notifly monitors Android notifications and sends them to your webhook endpoint.',
            ),
          ),
        ],
      ),
    );
  }
}
