import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../providers/settings_provider.dart';
import 'settings_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  final Set<String> _selectedPackages = {};
  List<Map<String, String>> _availableApps = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkPermission();
    await _loadNotifications();
    _listenToNotifications();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await NotificationService.instance.checkNotificationPermission();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final notifications = await DatabaseService.instance.getNotifications(limit: 100);
    final apps = await DatabaseService.instance.getDistinctApps();

    setState(() {
      _notifications = notifications;
      _availableApps = apps;
      _isLoading = false;
    });
  }

  void _listenToNotifications() {
    NotificationService.instance.notificationStream.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
      });
    });
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedPackages.isEmpty) {
      // Default: only show notifications from enabled apps
      return _notifications.where((notification) {
        return PreferencesService.instance.isAppEnabled(notification.packageName);
      }).toList();
    }
    // User has selected specific apps to filter
    return _notifications.where((notification) {
      return _selectedPackages.contains(notification.packageName);
    }).toList();
  }

  Future<void> _showAppFilterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter by Apps'),
          content: SizedBox(
            width: double.maxFinite,
            child: _availableApps.isEmpty
                ? const Center(child: Text('No apps with notifications'))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      CheckboxListTile(
                        title: const Text('Show All'),
                        value: _selectedPackages.isEmpty,
                        onChanged: (value) {
                          setDialogState(() {
                            setState(() {
                              if (value == true) {
                                _selectedPackages.clear();
                              }
                            });
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ..._availableApps.map((app) {
                        final packageName = app['packageName']!;
                        final appName = app['appName']!;
                        return CheckboxListTile(
                          title: Text(appName),
                          value: _selectedPackages.contains(packageName),
                          onChanged: (value) {
                            setDialogState(() {
                              setState(() {
                                if (value == true) {
                                  _selectedPackages.add(packageName);
                                } else {
                                  _selectedPackages.remove(packageName);
                                }
                              });
                            });
                          },
                        );
                      }),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifly'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedPackages.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_selectedPackages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showAppFilterDialog,
            tooltip: 'Filter by apps',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasPermission)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Column(
                children: [
                  const Text(
                    'Notification access required',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enable notification access for Notifly to monitor notifications.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await NotificationService.instance.openNotificationSettings();
                      await Future.delayed(const Duration(seconds: 1));
                      await _checkPermission();
                    },
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Webhook: ${settingsProvider.webhookEnabled ? "Enabled" : "Disabled"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (settingsProvider.webhookUrl.isNotEmpty)
                        Text(
                          settingsProvider.webhookUrl,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  settingsProvider.webhookEnabled ? Icons.check_circle : Icons.cancel,
                  color: settingsProvider.webhookEnabled ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? Center(
                        child: Text(
                          _selectedPackages.isNotEmpty
                              ? 'No notifications from selected apps'
                              : 'No notifications yet',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(
                                  notification.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          notification.appName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimestamp(notification.timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear Notifications'),
              content: const Text('Are you sure you want to clear all notifications?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Clear'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await DatabaseService.instance.clearAllNotifications();
            await _loadNotifications();
          }
        },
        child: const Icon(Icons.delete_sweep),
      ),
    );
  }
}
