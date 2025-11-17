import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/app_config_provider.dart';
import 'app_selection_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _webhookUrlController = TextEditingController();
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    _webhookUrlController.text = settingsProvider.webhookUrl;
  }

  @override
  void dispose() {
    _webhookUrlController.dispose();
    super.dispose();
  }

  Future<void> _testWebhook() async {
    setState(() {
      _isTesting = true;
    });

    final settingsProvider = context.read<SettingsProvider>();
    final success = await settingsProvider.testWebhook();

    setState(() {
      _isTesting = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Webhook test successful!' : 'Webhook test failed!',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
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
              'Webhook Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Webhook'),
            subtitle: const Text('Send notifications to webhook URL'),
            value: settingsProvider.webhookEnabled,
            onChanged: (value) {
              settingsProvider.toggleWebhook(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _webhookUrlController,
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                hintText: 'https://your-server.com/webhook',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                settingsProvider.setWebhookUrl(value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _testWebhook,
              icon: _isTesting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Test Webhook'),
            ),
          ),
          const Divider(),
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
          SwitchListTile(
            title: const Text('Monitor All Apps'),
            subtitle: Text(
              appConfigProvider.monitorAllApps
                  ? 'Monitoring all apps'
                  : 'Monitoring ${appConfigProvider.enabledAppCount} apps',
            ),
            value: appConfigProvider.monitorAllApps,
            onChanged: (value) {
              appConfigProvider.toggleMonitorAllApps(value);
            },
          ),
          ListTile(
            title: const Text('Select Apps'),
            subtitle: Text('${appConfigProvider.enabledAppCount} apps enabled'),
            trailing: const Icon(Icons.chevron_right),
            enabled: !appConfigProvider.monitorAllApps,
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
