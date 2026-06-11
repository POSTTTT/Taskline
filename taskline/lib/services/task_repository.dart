import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class TaskRepository {
  static const String tableName = 'tasks';

  // `deadline` is nullable: a NULL deadline marks a deadline-less "todo".
  static const String _createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id                   INTEGER PRIMARY KEY AUTOINCREMENT,
      title                TEXT NOT NULL,
      description          TEXT,
      deadline             TEXT,
      is_done              INTEGER NOT NULL DEFAULT 0,
      recurrence           TEXT NOT NULL DEFAULT 'none',
      recurrence_end_date  TEXT,
      created_at           TEXT NOT NULL
    )
  ''';

  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableName ADD COLUMN recurrence_end_date TEXT',
      );
    }
    if (oldVersion < 3) {
      // Drop the NOT NULL constraint on `deadline` so deadline-less todos can
      // be stored. SQLite can't ALTER a column's constraint, so rebuild the
      // table: rename, recreate (nullable) via createSchema, copy, drop.
      await db.execute('ALTER TABLE $tableName RENAME TO ${tableName}_old');
      await createSchema(db);
      await db.execute(
        'INSERT INTO $tableName '
        '(id, title, description, deadline, is_done, recurrence, '
        'recurrence_end_date, created_at) '
        'SELECT id, title, description, deadline, is_done, recurrence, '
        'recurrence_end_date, created_at FROM ${tableName}_old',
      );
      await db.execute('DROP TABLE ${tableName}_old');
    }
  }

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
    // Dated tasks first (soonest deadline first); deadline-less todos last,
    // newest todo first. `deadline IS NULL` is 0 for dated, 1 for todos.
    final rows = await _db.query(
      tableName,
      orderBy: 'deadline IS NULL, deadline ASC, created_at DESC',
    );
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
