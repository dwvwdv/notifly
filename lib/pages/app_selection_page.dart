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

  void _showWebhookDialog(BuildContext context, String packageName, String appName, List<String> currentWebhookUrls) {
    final List<TextEditingController> controllers = currentWebhookUrls.map((url) => TextEditingController(text: url)).toList();
    if (controllers.isEmpty) {
      controllers.add(TextEditingController());
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Webhooks for $appName'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configure webhook URLs for this app. You can add multiple URLs.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: controllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Webhook URL ${index + 1}',
                                  hintText: 'https://your-server.com/webhook',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setDialogState(() {
                                  controllers[index].dispose();
                                  controllers.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add URL'),
                  onPressed: () {
                    setDialogState(() {
                      controllers.add(TextEditingController());
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                for (var controller in controllers) {
                  controller.dispose();
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final urls = controllers
                    .map((c) => c.text.trim())
                    .where((text) => text.isNotEmpty)
                    .toList();

                final appConfigProvider = context.read<AppConfigProvider>();
                appConfigProvider.updateAppWebhookUrls(packageName, urls);

                for (var controller in controllers) {
                  controller.dispose();
                }
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${urls.length} webhook URL(s) updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
    }).toList()
      ..sort((a, b) {
        // Sort enabled apps to the top
        if (a.isEnabled && !b.isEnabled) return -1;
        if (!a.isEnabled && b.isEnabled) return 1;
        // If both have the same enabled status, sort by app name
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });

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
                                  if (config.webhookUrls.isNotEmpty)
                                    Text(
                                      '${config.webhookUrls.length} webhook URL(s) configured',
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
                                      color: config.webhookUrls.isNotEmpty
                                          ? Colors.blue
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      _showWebhookDialog(
                                        context,
                                        config.packageName,
                                        config.appName,
                                        config.webhookUrls,
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
