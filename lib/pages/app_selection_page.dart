import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_config_provider.dart';

class AppSelectionPage extends StatefulWidget {
  const AppSelectionPage({Key? key}) : super(key: key);

  @override
  State<AppSelectionPage> createState() => _AppSelectionPageState();
}

class _AppSelectionPageState extends State<AppSelectionPage> {
  String _searchQuery = '';

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
                            return SwitchListTile(
                              title: Text(config.appName),
                              subtitle: Text(
                                config.packageName,
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: config.isEnabled,
                              onChanged: (value) {
                                appConfigProvider.toggleApp(
                                  config.packageName,
                                  value,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
