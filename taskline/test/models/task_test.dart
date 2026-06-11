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

    test('daily task years in the past lands on the correct day and time', () {
      // Exercises the O(1) catch-up jump: 2023-01-01 to mid-2026 is ~1,250
      // daily steps, which the old loop walked one at a time.
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2023, 1, 1, 9, 0),
        recurrence: Recurrence.daily,
      );
      expect(
        task.nextOccurrenceAfter(DateTime.utc(2026, 6, 11, 8, 0)),
        DateTime.utc(2026, 6, 11, 9, 0),
      );
      // `from` past today's occurrence rolls to tomorrow's.
      expect(
        task.nextOccurrenceAfter(DateTime.utc(2026, 6, 11, 10, 0)),
        DateTime.utc(2026, 6, 12, 9, 0),
      );
    });

    test('an exact occurrence instant is returned, not skipped past', () {
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2023, 1, 1, 9, 0),
        recurrence: Recurrence.daily,
      );
      expect(
        task.nextOccurrenceAfter(DateTime.utc(2026, 6, 11, 9, 0)),
        DateTime.utc(2026, 6, 11, 9, 0),
      );
    });
  });

  group('Task.occurrencesIn', () {
    test('old daily task yields one occurrence per day in the window', () {
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2023, 1, 1, 9, 0),
        recurrence: Recurrence.daily,
      );
      final got = task
          .occurrencesIn(DateTime.utc(2026, 6, 1), DateTime.utc(2026, 6, 4))
          .toList();
      expect(got, [
        DateTime.utc(2026, 6, 1, 9, 0),
        DateTime.utc(2026, 6, 2, 9, 0),
        DateTime.utc(2026, 6, 3, 9, 0),
      ]);
    });

    test('old weekly task keeps its weekday and time across the jump', () {
      // 2023-01-02 is a Monday.
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2023, 1, 2, 10, 30),
        recurrence: Recurrence.weekly,
      );
      final got = task
          .occurrencesIn(DateTime.utc(2026, 6, 1), DateTime.utc(2026, 6, 15))
          .toList();
      expect(got, [
        DateTime.utc(2026, 6, 1, 10, 30), // a Monday
        DateTime.utc(2026, 6, 8, 10, 30),
      ]);
    });

    test('occurrence exactly at window start is included', () {
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2023, 1, 1, 0, 0),
        recurrence: Recurrence.daily,
      );
      final got = task
          .occurrencesIn(DateTime.utc(2026, 6, 1), DateTime.utc(2026, 6, 2))
          .toList();
      expect(got, [DateTime.utc(2026, 6, 1)]);
    });

    test('catch-up jump matches naive stepping for daily and weekly', () {
      for (final recurrence in [Recurrence.daily, Recurrence.weekly]) {
        final deadline = DateTime.utc(2024, 3, 7, 14, 45);
        final task = Task(
          title: 't',
          deadline: deadline,
          recurrence: recurrence,
        );
        final start = DateTime.utc(2026, 6, 5, 3, 0);
        final end = DateTime.utc(2026, 7, 5, 3, 0);

        // Reference: step one occurrence at a time, the pre-jump behavior.
        final step = recurrence == Recurrence.daily
            ? const Duration(days: 1)
            : const Duration(days: 7);
        final expected = <DateTime>[];
        var cursor = deadline;
        while (cursor.isBefore(start)) {
          cursor = cursor.add(step);
        }
        while (cursor.isBefore(end)) {
          expected.add(cursor);
          cursor = cursor.add(step);
        }

        expect(task.occurrencesIn(start, end).toList(), expected,
            reason: 'recurrence: $recurrence');
      }
    });

    test('monthly clamps to short months and recovers the anchor day', () {
      // Matches occursOn's rule: a deadline on the 31st fires on the last
      // day of shorter months and returns to the 31st where it exists.
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2026, 1, 31, 9, 0),
        recurrence: Recurrence.monthly,
      );
      final got = task
          .occurrencesIn(DateTime.utc(2026, 1, 1), DateTime.utc(2026, 6, 1))
          .toList();
      expect(got, [
        DateTime.utc(2026, 1, 31, 9, 0),
        DateTime.utc(2026, 2, 28, 9, 0),
        DateTime.utc(2026, 3, 31, 9, 0),
        DateTime.utc(2026, 4, 30, 9, 0),
        DateTime.utc(2026, 5, 31, 9, 0),
      ]);
    });

    test('monthly clamp respects leap years', () {
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2023, 12, 31, 9, 0),
        recurrence: Recurrence.monthly,
      );
      final got = task
          .occurrencesIn(DateTime.utc(2024, 2, 1), DateTime.utc(2024, 4, 1))
          .toList();
      expect(got, [
        DateTime.utc(2024, 2, 29, 9, 0), // leap February keeps day 29
        DateTime.utc(2024, 3, 31, 9, 0),
      ]);
    });

    test('nextOccurrenceAfter clamps monthly into a short month', () {
      final task = Task(
        title: 't',
        deadline: DateTime.utc(2026, 1, 31, 9, 0),
        recurrence: Recurrence.monthly,
      );
      expect(
        task.nextOccurrenceAfter(DateTime.utc(2026, 2, 1)),
        DateTime.utc(2026, 2, 28, 9, 0),
      );
      // Past the clamped February occurrence, the anchor day returns.
      expect(
        task.nextOccurrenceAfter(DateTime.utc(2026, 3, 1)),
        DateTime.utc(2026, 3, 31, 9, 0),
      );
    });
  });
}
