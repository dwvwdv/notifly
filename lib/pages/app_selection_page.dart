import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_config_provider.dart';
import '../providers/settings_provider.dart';
import '../services/webhook_service.dart';
import 'app_filter_rules_page.dart';

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

    // Track testing state for each URL: null = not tested, true = testing, false = tested
    final Map<int, bool?> testingStates = {};
    final Map<int, bool> testResults = {}; // true = success, false = failed

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> testWebhookUrl(int index) async {
            final url = controllers[index].text.trim();
            if (url.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('請先輸入 Webhook URL')),
              );
              return;
            }

            setDialogState(() {
              testingStates[index] = true;
            });

            try {
              final settingsProvider = context.read<SettingsProvider>();
              final success = await WebhookService.instance.testWebhook(
                url,
                headers: settingsProvider.webhookHeaders,
              );

              setDialogState(() {
                testingStates[index] = false;
                testResults[index] = success;
              });

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Webhook 測試成功！' : 'Webhook 測試失敗'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            } catch (e) {
              setDialogState(() {
                testingStates[index] = false;
                testResults[index] = false;
              });
            }
          }

          return AlertDialog(
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
                        final isTesting = testingStates[index] == true;
                        final hasResult = testResults.containsKey(index);
                        final testSuccess = testResults[index] ?? false;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controllers[index],
                                      decoration: InputDecoration(
                                        labelText: 'Webhook URL ${index + 1}',
                                        hintText: 'https://your-server.com/webhook',
                                        border: const OutlineInputBorder(),
                                        suffixIcon: hasResult
                                            ? Icon(
                                                testSuccess ? Icons.check_circle : Icons.error,
                                                color: testSuccess ? Colors.green : Colors.red,
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        // Clear test result when URL changes
                                        setDialogState(() {
                                          testingStates.remove(index);
                                          testResults.remove(index);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      setDialogState(() {
                                        controllers[index].dispose();
                                        controllers.removeAt(index);
                                        // Reindex testing states
                                        final newTestingStates = <int, bool?>{};
                                        final newTestResults = <int, bool>{};
                                        for (var i = 0; i < controllers.length; i++) {
                                          if (i < index) {
                                            if (testingStates.containsKey(i)) {
                                              newTestingStates[i] = testingStates[i];
                                            }
                                            if (testResults.containsKey(i)) {
                                              newTestResults[i] = testResults[i]!;
                                            }
                                          } else if (i >= index) {
                                            if (testingStates.containsKey(i + 1)) {
                                              newTestingStates[i] = testingStates[i + 1];
                                            }
                                            if (testResults.containsKey(i + 1)) {
                                              newTestResults[i] = testResults[i + 1]!;
                                            }
                                          }
                                        }
                                        testingStates.clear();
                                        testingStates.addAll(newTestingStates);
                                        testResults.clear();
                                        testResults.addAll(newTestResults);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: ElevatedButton.icon(
                                  onPressed: isTesting ? null : () => testWebhookUrl(index),
                                  icon: isTesting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.send, size: 16),
                                  label: Text(isTesting ? '測試中...' : '測試 Webhook'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
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
          );
        },
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
                                  if (config.filterRules.isNotEmpty)
                                    Text(
                                      '${config.filterRules.length} 個過濾規則',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade700,
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
                                    tooltip: 'Webhook URLs',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.filter_alt,
                                      color: config.filterRules.isNotEmpty
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AppFilterRulesPage(
                                            appConfig: config,
                                            onUpdate: (updatedConfig) {
                                              appConfigProvider.updateAppConfig(updatedConfig);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    tooltip: '進階條件',
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
