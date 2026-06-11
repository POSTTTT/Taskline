import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';

import 'models/app_settings.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/task_edit_screen.dart';
import 'services/notification_service.dart';
import 'services/single_instance.dart';
import 'services/tray_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against multiple instances. Subsequent launches signal this one
  // over the socket and we surface the window via window_manager (which is
  // what hid it in the first place, so the show is a real reversal).
  if (!await SingleInstance.acquireOrForward(onActivate: _surfaceWindow)) {
    return;
  }

  await NotificationService.instance.init();

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    launchAtStartup.setup(
      appName: 'Taskline',
      appPath: Platform.resolvedExecutable,
    );
    await TrayService.instance.init(onNewTask: _openNewTaskFromTray);
  }

  runApp(const ProviderScope(child: TasklineApp()));
}

Future<void> _surfaceWindow() async {
  // Called from inside the first instance when a second launch signals us.
  // window_manager is already initialised by TrayService at this point
  // (TrayService.init runs synchronously after socket bind, before runApp).
  try {
    await windowManager.show();
    await windowManager.focus();
  } catch (_) {
    // window_manager may not be ready in pathological race conditions;
    // a no-op here just means the user has to click the tray icon.
  }
}

void _openNewTaskFromTray() {
  final nav = rootNavigatorKey.currentState;
  if (nav == null) return;
  nav.push(MaterialPageRoute(builder: (_) => const TaskEditScreen()));
}

class TasklineApp extends ConsumerWidget {
  const TasklineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync the global AppColors brightness + palette from saved settings.
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final desired = settings.themeMode == ThemeModePref.dark
        ? Brightness.dark
        : Brightness.light;
    if (appBrightness.value != desired) {
      // Defer so we don't update during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appBrightness.value = desired;
      });
    }
    final desiredPalette = paletteById(settings.palette.name);
    if (appPalette.value != desiredPalette) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appPalette.value = desiredPalette;
      });
    }

    // Rebuild whenever brightness or palette changes (the post-frame callbacks
    // above and the settings update both flow through here).
    return ListenableBuilder(
      listenable: Listenable.merge([appBrightness, appPalette]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Taskline',
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          theme: buildAppTheme(),
          // Non-const so palette/brightness changes (which rebuild MaterialApp)
          // propagate into HomeScreen instead of being skipped as identical.
          home: HomeScreen(),
        );
      },
    );
  }
}
