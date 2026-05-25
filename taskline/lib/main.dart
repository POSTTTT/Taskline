import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:window_manager/window_manager.dart';

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

class TasklineApp extends StatelessWidget {
  const TasklineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taskline',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: buildAppTheme(),
      home: const HomeScreen(),
    );
  }
}
