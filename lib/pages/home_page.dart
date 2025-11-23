import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import '../providers/settings_provider.dart';
import 'settings_page.dart';
import 'package:intl/intl.dart';

enum FilterMode { detectingApp, showAll, custom }

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
  FilterMode _filterMode = FilterMode.detectingApp;

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
    if (_filterMode == FilterMode.showAll) {
      // Show ALL notifications from ALL apps
      return _notifications;
    }

    if (_filterMode == FilterMode.detectingApp) {
      // Show only notifications from enabled apps
      return _notifications.where((notification) {
        return PreferencesService.instance.isAppEnabled(notification.packageName);
      }).toList();
    }

    // Custom filter: show only selected apps
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
            child: ListView(
              shrinkWrap: true,
              children: [
                CheckboxListTile(
                  title: const Text('Detecting App'),
                  subtitle: const Text('Show only enabled apps'),
                  value: _filterMode == FilterMode.detectingApp,
                  onChanged: (value) {
                    setDialogState(() {
                      setState(() {
                        if (value == true) {
                          _filterMode = FilterMode.detectingApp;
                          _selectedPackages.clear();
                        }
                      });
                    });
                    Navigator.pop(context);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Show All'),
                  subtitle: const Text('Show all apps regardless of settings'),
                  value: _filterMode == FilterMode.showAll,
                  onChanged: (value) {
                    setDialogState(() {
                      setState(() {
                        if (value == true) {
                          _filterMode = FilterMode.showAll;
                          _selectedPackages.clear();
                        }
                      });
                    });
                    Navigator.pop(context);
                  },
                ),
                if (_availableApps.isNotEmpty) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Or select specific apps:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
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
                              _filterMode = FilterMode.custom;
                              _selectedPackages.add(packageName);
                            } else {
                              _selectedPackages.remove(packageName);
                              // If no apps are selected, revert to detecting app mode
                              if (_selectedPackages.isEmpty) {
                                _filterMode = FilterMode.detectingApp;
                              }
                            }
                          });
                        });
                      },
                    );
                  }),
                ],
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

  Widget _buildNotificationCard(NotificationModel notification) {
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
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hookfy'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_filterMode != FilterMode.detectingApp)
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
                    'Please enable notification access for Hookfy to monitor notifications.',
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
                            final card = _buildNotificationCard(notification);

                            // 根據設定決定是否啟用滑動刪除
                            if (!settingsProvider.swipeToDeleteEnabled) {
                              return card;
                            }

                            return Dismissible(
                              key: Key('notification_${notification.id}'),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              onDismissed: (direction) async {
                                // Capture ScaffoldMessenger before async gap
                                final scaffoldMessenger = ScaffoldMessenger.of(context);

                                // Remove from database
                                await DatabaseService.instance.deleteNotification(notification.id!);

                                // Remove from local list
                                setState(() {
                                  _notifications.removeWhere((n) => n.id == notification.id);
                                });

                                // Show snackbar
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('已刪除 ${notification.appName} 的通知'),
                                      duration: const Duration(seconds: 2),
                                      action: SnackBarAction(
                                        label: '復原',
                                        onPressed: () async {
                                          // Re-insert notification
                                          await DatabaseService.instance.insertNotification(notification);
                                          await _loadNotifications();
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: card,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Determine what will be cleared based on filter mode
          String dialogContent;
          if (_filterMode == FilterMode.showAll) {
            dialogContent = 'Are you sure you want to clear all notifications?';
          } else if (_filterMode == FilterMode.detectingApp) {
            dialogContent = 'Are you sure you want to clear notifications from enabled apps?';
          } else {
            final appCount = _selectedPackages.length;
            dialogContent = 'Are you sure you want to clear notifications from $appCount selected app${appCount > 1 ? 's' : ''}?';
          }

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Clear Notifications'),
              content: Text(dialogContent),
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
            if (_filterMode == FilterMode.showAll) {
              // Clear all notifications
              await DatabaseService.instance.clearAllNotifications();
            } else if (_filterMode == FilterMode.detectingApp) {
              // Clear only notifications from enabled apps
              final enabledPackages = _notifications
                  .where((n) => PreferencesService.instance.isAppEnabled(n.packageName))
                  .map((n) => n.packageName)
                  .toSet()
                  .toList();
              await DatabaseService.instance.deleteNotificationsByPackages(enabledPackages);
            } else {
              // Clear only notifications from selected apps
              await DatabaseService.instance.deleteNotificationsByPackages(_selectedPackages.toList());
            }
            await _loadNotifications();
          }
        },
        child: const Icon(Icons.delete_sweep),
      ),
    );
  }
}
