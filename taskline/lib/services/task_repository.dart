import 'package:sqflite_common/sqlite_api.dart';

import '../models/task.dart';

class TaskRepository {
  static const String tableName = 'tasks';

  static const String _createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      title       TEXT NOT NULL,
      description TEXT,
      deadline    TEXT NOT NULL,
      is_done     INTEGER NOT NULL DEFAULT 0,
      recurrence  TEXT NOT NULL DEFAULT 'none',
      created_at  TEXT NOT NULL
    )
  ''';

  final Database _db;

  TaskRepository(this._db);

  static Future<void> createSchema(Database db) async {
    await db.execute(_createTableSql);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON $tableName(deadline)',
    );
  }

  Future<Task> create(Task task) async {
    final id = await _db.insert(tableName, task.toMap());
    return task.copyWith(id: id);
  }

  Future<Task?> getById(int id) async {
    final rows = await _db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  Future<List<Task>> getAll() async {
    final rows = await _db.query(tableName, orderBy: 'deadline ASC');
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getUpcoming({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await _db.query(
      tableName,
      where: 'is_done = 0 AND deadline >= ?',
      whereArgs: [cutoff],
      orderBy: 'deadline ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<List<Task>> getOverdue({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).toUtc().toIso8601String();
    final rows = await _db.query(
      tableName,
      where: 'is_done = 0 AND deadline < ?',
      whereArgs: [cutoff],
      orderBy: 'deadline ASC',
    );
    return rows.map(Task.fromMap).toList();
  }

  Future<int> update(Task task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update a task without an id');
    }
    return _db.update(
      tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    return _db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAll() async {
    return _db.delete(tableName);
  }
}
