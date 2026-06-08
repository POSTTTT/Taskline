import 'package:flutter_test/flutter_test.dart';
import 'package:taskline/models/task.dart';

void main() {
  group('Task', () {
    test('stores deadline and createdAt as UTC', () {
      final localDeadline = DateTime(2026, 6, 1, 9, 0);
      final task = Task(title: 'Pay bill', deadline: localDeadline);
      expect(task.deadline!.isUtc, isTrue);
      expect(task.createdAt.isUtc, isTrue);
    });

    test('a deadline-less todo has null deadline and isTodo true', () {
      final todo = Task(title: 'Side project idea');
      expect(todo.deadline, isNull);
      expect(todo.isTodo, isTrue);
      // No calendar presence for todos.
      expect(todo.occursOn(DateTime(2026, 6, 1)), isFalse);
      expect(
        todo
            .occurrencesIn(DateTime(2020), DateTime(2030))
            .toList(),
        isEmpty,
      );
      expect(todo.nextOccurrenceAfter(DateTime(2020)), isNull);
    });

    test('todo toMap / fromMap roundtrip preserves null deadline', () {
      final todo = Task(
        id: 3,
        title: 'Write blog post',
        recurrence: Recurrence.weekly, // nudge cadence for a todo
        createdAt: DateTime.utc(2026, 5, 17, 10, 0),
      );
      final restored = Task.fromMap(todo.toMap());
      expect(restored.deadline, isNull);
      expect(restored, equals(todo));
    });

    test('copyWith can clear a deadline to make a task a todo', () {
      final scheduled = Task(
        title: 't',
        deadline: DateTime.utc(2026, 1, 1),
      );
      final asTodo = scheduled.copyWith(deadline: null);
      expect(asTodo.deadline, isNull);
      expect(asTodo.isTodo, isTrue);
    });

    test('toMap / fromMap roundtrip preserves all fields', () {
      final original = Task(
        id: 7,
        title: 'Renew passport',
        description: 'Bring two photos',
        deadline: DateTime.utc(2026, 12, 31, 17, 30),
        isDone: true,
        recurrence: Recurrence.weekly,
        createdAt: DateTime.utc(2026, 5, 17, 10, 0),
      );

      final restored = Task.fromMap(original.toMap());

      expect(restored, equals(original));
    });

    test('toMap omits id when null so SQLite assigns one', () {
      final task = Task(title: 't', deadline: DateTime.utc(2026, 1, 1));
      expect(task.toMap().containsKey('id'), isFalse);
    });

    test('is_done stored as 0/1 integer', () {
      final done = Task(
        title: 't',
        deadline: DateTime.utc(2026, 1, 1),
        isDone: true,
      ).toMap();
      final notDone = Task(
        title: 't',
        deadline: DateTime.utc(2026, 1, 1),
      ).toMap();

      expect(done['is_done'], 1);
      expect(notDone['is_done'], 0);
    });

    test('recurrenceFromString falls back to none for unknown values', () {
      expect(recurrenceFromString('yearly'), Recurrence.none);
      expect(recurrenceFromString(''), Recurrence.none);
      expect(recurrenceFromString('daily'), Recurrence.daily);
    });
  });

  group('Task.nextOccurrenceAfter', () {
    final base = DateTime.utc(2026, 5, 17, 9, 0);

    test('returns deadline itself when in the future', () {
      final task = Task(title: 't', deadline: base.add(const Duration(days: 1)));
      final next = task.nextOccurrenceAfter(base);
      expect(next, task.deadline);
    });

    test('returns null for past one-off task', () {
      final task = Task(
        title: 't',
        deadline: base.subtract(const Duration(days: 1)),
      );
      expect(task.nextOccurrenceAfter(base), isNull);
    });

    test('advances by one day for daily recurrence', () {
      final task = Task(
        title: 't',
        deadline: base.subtract(const Duration(days: 3)),
        recurrence: Recurrence.daily,
      );
      final next = task.nextOccurrenceAfter(base);
      expect(next, isNotNull);
      expect(next!.isAfter(base) || next.isAtSameMomentAs(base), isTrue);
      expect(next.difference(base).inDays, lessThan(1));
    });

    test('advances by seven days for weekly recurrence', () {
      final task = Task(
        title: 't',
        deadline: base.subtract(const Duration(days: 10)),
        recurrence: Recurrence.weekly,
      );
      final next = task.nextOccurrenceAfter(base)!;
      expect(next.isAfter(base) || next.isAtSameMomentAs(base), isTrue);
      expect(next.weekday, base.subtract(const Duration(days: 10)).weekday);
    });

    test('monthly recurrence advances by calendar month', () {
      final start = DateTime.utc(2026, 1, 15, 9, 0);
      final from = DateTime.utc(2026, 3, 1, 0, 0);
      final task = Task(
        title: 't',
        deadline: start,
        recurrence: Recurrence.monthly,
      );
      final next = task.nextOccurrenceAfter(from);
      expect(next, DateTime.utc(2026, 3, 15, 9, 0));
    });
  });
}
