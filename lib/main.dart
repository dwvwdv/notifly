import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/preferences_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'providers/settings_provider.dart';
import 'providers/app_config_provider.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await PreferencesService.instance.init();
  await NotificationService.instance.init();
  BackgroundService.instance.init();

  // Start background service if enabled
  if (PreferencesService.instance.getBackgroundServiceEnabled()) {
    await BackgroundService.instance.startService();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppConfigProvider()..init(),
        ),
      ],
      child: MaterialApp(
        title: 'Notifly',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const WithForegroundTask(child: HomePage()),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class WithForegroundTask extends StatelessWidget {
  const WithForegroundTask({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: child,
    );
  }
}
