import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import 'screens/home_screen.dart';
import 'screens/task_edit_screen.dart';
import 'services/notification_service.dart';
import 'services/tray_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
