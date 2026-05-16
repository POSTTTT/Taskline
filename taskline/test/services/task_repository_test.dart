import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:taskline/models/task.dart';
import 'package:taskline/services/task_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late TaskRepository repo;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await TaskRepository.createSchema(db);
    repo = TaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Task sample({
    String title = 'Pay bill',
    DateTime? deadline,
    bool isDone = false,
    Recurrence recurrence = Recurrence.none,
  }) {
    return Task(
      title: title,
      deadline: deadline ?? DateTime.utc(2026, 6, 1, 9, 0),
      isDone: isDone,
      recurrence: recurrence,
    );
  }

  group('TaskRepository CRUD', () {
    test('create assigns an id and persists fields', () async {
      final saved = await repo.create(sample(title: 'Electric bill'));
      expect(saved.id, isNotNull);

      final found = await repo.getById(saved.id!);
      expect(found, isNotNull);
      expect(found!.title, 'Electric bill');
    });

    test('getById returns null when missing', () async {
      expect(await repo.getById(9999), isNull);
    });

    test('getAll returns tasks ordered by deadline ascending', () async {
      await repo.create(sample(
        title: 'Later',
        deadline: DateTime.utc(2026, 7, 1),
      ));
      await repo.create(sample(
        title: 'Sooner',
        deadline: DateTime.utc(2026, 6, 1),
      ));
      await repo.create(sample(
        title: 'Middle',
        deadline: DateTime.utc(2026, 6, 15),
      ));

      final all = await repo.getAll();
      expect(all.map((t) => t.title).toList(), ['Sooner', 'Middle', 'Later']);
    });

    test('update changes fields by id', () async {
      final saved = await repo.create(sample(title: 'Old'));
      await repo.update(saved.copyWith(title: 'New', isDone: true));

      final found = await repo.getById(saved.id!);
      expect(found!.title, 'New');
      expect(found.isDone, isTrue);
    });

    test('update throws when task has no id', () async {
      expect(
        () => repo.update(sample()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('delete removes a task', () async {
      final saved = await repo.create(sample());
      expect(await repo.delete(saved.id!), 1);
      expect(await repo.getById(saved.id!), isNull);
    });

    test('deleteAll clears the table', () async {
      await repo.create(sample(title: 'a'));
      await repo.create(sample(title: 'b'));
      await repo.deleteAll();
      expect(await repo.getAll(), isEmpty);
    });
  });

  group('TaskRepository queries', () {
    test('getUpcoming returns only future, not-done tasks', () async {
      final now = DateTime.utc(2026, 5, 17, 12, 0);

      final past = await repo.create(sample(
        deadline: now.subtract(const Duration(days: 1)),
      ));
      final future = await repo.create(sample(
        title: 'Future',
        deadline: now.add(const Duration(days: 1)),
      ));
      final futureDone = await repo.create(sample(
        title: 'Future done',
        deadline: now.add(const Duration(days: 2)),
        isDone: true,
      ));

      final upcoming = await repo.getUpcoming(now: now);
      final ids = upcoming.map((t) => t.id).toSet();
      expect(ids, {future.id});
      expect(ids.contains(past.id), isFalse);
      expect(ids.contains(futureDone.id), isFalse);
    });

    test('getOverdue returns past, not-done tasks', () async {
      final now = DateTime.utc(2026, 5, 17, 12, 0);

      final past = await repo.create(sample(
        deadline: now.subtract(const Duration(days: 1)),
      ));
      await repo.create(sample(
        title: 'Future',
        deadline: now.add(const Duration(days: 1)),
      ));
      await repo.create(sample(
        title: 'Past done',
        deadline: now.subtract(const Duration(days: 2)),
        isDone: true,
      ));

      final overdue = await repo.getOverdue(now: now);
      expect(overdue.length, 1);
      expect(overdue.single.id, past.id);
    });
  });
}
