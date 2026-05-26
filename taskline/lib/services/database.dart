import 'dart:io' show Platform;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'task_repository.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'taskline.db');

    final factory = _resolveFactory();
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) => TaskRepository.createSchema(db),
        onUpgrade: TaskRepository.migrate,
      ),
    );

    return AppDatabase._(db);
  }

  static DatabaseFactory _resolveFactory() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    // iOS / Android: use the native sqflite plugin's default factory.
    return sqflite.databaseFactory;
  }

  Future<void> close() => database.close();
}
