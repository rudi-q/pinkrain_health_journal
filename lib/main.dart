import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/router.dart';
import 'core/services/hive_service.dart';
import 'features/treatment/services/daily_reset_service.dart';
import 'features/treatment/services/medication_notification_service.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  
  // Initialize notification service at app startup
  final notificationService = MedicationNotificationService();
  await notificationService.initialize();
  
  // Initialize daily reset service
  final dailyResetService = DailyResetService();
  dailyResetService.initialize();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: ThemeMode.light, // This will use the device's theme settings
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Outfit',
        primarySwatch: Colors.pink,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Outfit',
        primarySwatch: Colors.pink,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
    );
  }
}