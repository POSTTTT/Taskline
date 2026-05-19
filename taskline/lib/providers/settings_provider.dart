import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final loaded = await SettingsService.instance.load();
    await _applyLaunchAtStartup(loaded.launchAtStartup);
    return loaded;
  }

  Future<void> save(AppSettings next) async {
    state = AsyncData(next);
    await SettingsService.instance.save(next);
    await _applyLaunchAtStartup(next.launchAtStartup);
  }

  Future<void> _applyLaunchAtStartup(bool enabled) async {
    if (!(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return;
    }
    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
    } catch (_) {
      // Silently swallow — the registry write can fail in dev runs (debug exe
      // path is ephemeral). The setting still persists and will reapply once
      // the app is properly installed.
    }
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
