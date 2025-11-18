import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_config_provider.dart';

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({super.key});

  @override
  State<AppSelectionPage> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  String _searchQuery = '';

  void _showWebhookDialog(BuildContext context, String packageName, String appName, String? currentWebhookUrl) {
    final TextEditingController controller = TextEditingController(text: currentWebhookUrl ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Webhook for $appName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set a custom webhook URL for this app. Leave empty to use the global webhook URL.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Webhook URL',
                hintText: 'https://your-server.com/webhook',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final appConfigProvider = context.read<AppConfigProvider>();
              appConfigProvider.updateAppWebhook(
                packageName,
                controller.text.isEmpty ? null : controller.text,
              );
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Webhook URL updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appConfigProvider = context.watch<AppConfigProvider>();

    final filteredApps = appConfigProvider.appConfigs.where((config) {
      if (_searchQuery.isEmpty) return true;
      return config.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search apps...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: appConfigProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${appConfigProvider.enabledAppCount} of ${appConfigProvider.appConfigs.length} apps enabled',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Enable all
                          for (var config in appConfigProvider.appConfigs) {
                            appConfigProvider.toggleApp(config.packageName, true);
                          }
                        },
                        child: const Text('Enable All'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Disable all
                          for (var config in appConfigProvider.appConfigs) {
                            appConfigProvider.toggleApp(config.packageName, false);
                          }
                        },
                        child: const Text('Disable All'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredApps.isEmpty
                      ? const Center(child: Text('No apps found'))
                      : ListView.builder(
                          itemCount: filteredApps.length,
                          itemBuilder: (context, index) {
                            final config = filteredApps[index];
                            return ListTile(
                              title: Text(config.appName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    config.packageName,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (config.webhookUrl != null && config.webhookUrl!.isNotEmpty)
                                    Text(
                                      'Custom webhook: ${config.webhookUrl}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue.shade700,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.webhook,
                                      color: config.webhookUrl != null && config.webhookUrl!.isNotEmpty
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _showWebhookDialog(
                                        context,
                                        config.packageName,
                                        config.appName,
                                        config.webhookUrl,
                                      );
                                    },
                                  ),
                                  Switch(
                                    value: config.isEnabled,
                                    onChanged: (value) {
                                      appConfigProvider.toggleApp(
                                        config.packageName,
                                        value,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
