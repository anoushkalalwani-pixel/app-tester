import 'package:flutter/material.dart';
import 'homepage.dart';
import 'pomodoro/pomodoro_controller.dart';
import 'sync/sync_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  // Restores the user's configured Pomodoro durations before the first frame.
  await PomodoroController.instance.load();
  // Loads any locally-persisted study data into memory (offline-first) and,
  // when enabled, reconciles it with the cloud backup in the background.
  await SyncService.instance.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.themeMode,
          // Cross-fade the whole palette (backgrounds, cards, text) when the
          // user flips between light and dark, rather than snapping.
          themeAnimationDuration: AppDurations.slow,
          themeAnimationCurve: Curves.easeInOut,
          home: HomePage(),
        );
      },
    );
  }
}
