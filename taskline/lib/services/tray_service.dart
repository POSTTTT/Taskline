import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the Windows system-tray icon and its right-click menu.
///
/// On Windows the close (X) button hides the window to the tray rather than
/// quitting, so scheduled notifications keep working and the user can re-open
/// the app from the tray. Quit is exposed in the tray menu.
class TrayService with TrayListener, WindowListener {
  TrayService._();

  static final TrayService instance = TrayService._();

  bool _initialized = false;
  VoidCallback? _onNewTask;

  Future<void> init({VoidCallback? onNewTask}) async {
    if (_initialized) return;
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }

    _onNewTask = onNewTask;

    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true); // close → hide instead
    windowManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );
    await trayManager.setToolTip('Taskline');
    await _rebuildMenu();
    trayManager.addListener(this);

    _initialized = true;
  }

  Future<void> _rebuildMenu() async {
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Show Taskline'),
      MenuItem(key: 'new_task', label: 'New task…'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit Taskline'),
    ]));
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconMouseDown() => _showWindow();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await _showWindow();
        break;
      case 'new_task':
        await _showWindow();
        _onNewTask?.call();
        break;
      case 'quit':
        await trayManager.destroy();
        await windowManager.setPreventClose(false);
        await windowManager.close();
        break;
    }
  }

  @override
  void onWindowClose() async {
    // Hide instead of quitting; user can quit from the tray menu.
    await windowManager.hide();
  }
}
