enum Recurrence { none, daily, weekly, monthly }

Recurrence recurrenceFromString(String value) {
  return Recurrence.values.firstWhere(
    (r) => r.name == value,
    orElse: () => Recurrence.none,
  );
}

class Task {
  final int? id;
  final String title;
  final String? description;

  /// The due date/time, in UTC. `null` means this is a deadline-less "todo"
  /// (a someday/backlog item). For a todo, [recurrence] is reinterpreted as an
  /// optional "remind me" nudge cadence rather than a repeating deadline.
  final DateTime? deadline;
  final bool isDone;
  final Recurrence recurrence;
  final DateTime? recurrenceEndDate;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    DateTime? deadline,
    this.isDone = false,
    this.recurrence = Recurrence.none,
    DateTime? recurrenceEndDate,
    DateTime? createdAt,
  })  : deadline = deadline?.toUtc(),
        recurrenceEndDate = recurrenceEndDate?.toUtc(),
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  /// True when this is a deadline-less todo rather than a scheduled task.
  bool get isTodo => deadline == null;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    Object? deadline = _sentinel,
    bool? isDone,
    Recurrence? recurrence,
    Object? recurrenceEndDate = _sentinel,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: identical(deadline, _sentinel)
          ? this.deadline
          : deadline as DateTime?,
      isDone: isDone ?? this.isDone,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: identical(recurrenceEndDate, _sentinel)
          ? this.recurrenceEndDate
          : recurrenceEndDate as DateTime?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static const Object _sentinel = Object();

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'is_done': isDone ? 1 : 0,
      'recurrence': recurrence.name,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    final endRaw = map['recurrence_end_date'] as String?;
    final deadlineRaw = map['deadline'] as String?;
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: deadlineRaw == null ? null : DateTime.parse(deadlineRaw),
      isDone: (map['is_done'] as int) == 1,
      recurrence: recurrenceFromString(map['recurrence'] as String),
      recurrenceEndDate: endRaw == null ? null : DateTime.parse(endRaw),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Returns true if a recurrence (or the original deadline) lands on `day`
  /// in local time. Used by the calendar to mark days and filter the list.
  bool occursOn(DateTime day) {
    final dl = deadline;
    if (dl == null) return false; // deadline-less todos never land on a day
    final localDay = DateTime(day.year, day.month, day.day);
    final localDeadline = dl.toLocal();
    final deadlineDay = DateTime(
        localDeadline.year, localDeadline.month, localDeadline.day);

    if (localDay.isBefore(deadlineDay)) return false;

    if (recurrenceEndDate != null) {
      final localEnd = recurrenceEndDate!.toLocal();
      final endDay = DateTime(localEnd.year, localEnd.month, localEnd.day);
      if (localDay.isAfter(endDay)) return false;
    }

    switch (recurrence) {
      case Recurrence.none:
        return localDay == deadlineDay;
      case Recurrence.daily:
        return true;
      case Recurrence.weekly:
        return localDay.weekday == deadlineDay.weekday;
      case Recurrence.monthly:
        // Monthly on the same day-of-month. If the deadline is the 31st and
        // a month has fewer days, fall through to the last day of that month.
        if (localDay.day == localDeadline.day) return true;
        final lastDayOfMonth =
            DateTime(localDay.year, localDay.month + 1, 0).day;
        return localDeadline.day > lastDayOfMonth &&
            localDay.day == lastDayOfMonth;
    }
  }

  /// All occurrence datetimes in `[start, end)`. Useful for building the
  /// calendar's task list, where each occurrence becomes its own row.
  Iterable<DateTime> occurrencesIn(DateTime start, DateTime end) sync* {
    final dl = deadline;
    if (dl == null) return; // todos have no calendar occurrences
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final effectiveEnd = recurrenceEndDate != null &&
            recurrenceEndDate!.isBefore(endUtc)
        ? DateTime.utc(recurrenceEndDate!.year, recurrenceEndDate!.month,
                recurrenceEndDate!.day)
            .add(const Duration(days: 1)) // include the end date itself
        : endUtc;

    if (recurrence == Recurrence.none) {
      if (!dl.isBefore(startUtc) && dl.isBefore(endUtc)) {
        yield dl;
      }
      return;
    }

    if (recurrence == Recurrence.monthly) {
      // Monthly occurrences are generated by index from the deadline anchor,
      // not by stepping: clamped dates (Jan 31 → Feb 28 → Mar 31) can't be
      // derived from the previous occurrence alone.
      for (var k = _monthsCatchUp(dl, startUtc);; k++) {
        final occurrence = _monthlyOccurrence(dl, k);
        if (!occurrence.isBefore(effectiveEnd)) return;
        yield occurrence;
      }
    }

    final step = recurrence == Recurrence.daily
        ? const Duration(days: 1)
        : const Duration(days: 7);
    var current = _catchUpTo(dl, startUtc);
    while (current.isBefore(effectiveEnd)) {
      yield current;
      current = current.add(step);
    }
  }

  /// The first occurrence at or after [target], starting from occurrence
  /// [from] and advancing by this task's recurrence. A single arithmetic
  /// jump rather than one step per missed occurrence — stepping is
  /// O(task age), which the calendar pays repeatedly for old recurring tasks.
  DateTime _catchUpTo(DateTime from, DateTime target) {
    if (!from.isBefore(target)) return from;
    switch (recurrence) {
      case Recurrence.none:
        return from; // callers handle none before stepping
      case Recurrence.daily:
      case Recurrence.weekly:
        final stepUs = recurrence == Recurrence.daily
            ? Duration.microsecondsPerDay
            : Duration.microsecondsPerDay * 7;
        final behindUs = target.difference(from).inMicroseconds;
        final steps = (behindUs + stepUs - 1) ~/ stepUs; // ceil division
        return from.add(Duration(microseconds: steps * stepUs));
      case Recurrence.monthly:
        return _monthlyOccurrence(from, _monthsCatchUp(from, target));
    }
  }

  /// The [monthsAfter]-th monthly occurrence of [anchor]: same day-of-month,
  /// clamped to the last day of shorter months, keeping [anchor]'s
  /// time-of-day. A deadline on the 31st fires on Feb 28, then back on
  /// Mar 31 — the same rule [occursOn] applies when marking calendar days.
  DateTime _monthlyOccurrence(DateTime anchor, int monthsAfter) {
    final month = anchor.month + monthsAfter;
    final lastDay = DateTime.utc(anchor.year, month + 1, 0).day;
    return DateTime.utc(
      anchor.year,
      month,
      anchor.day <= lastDay ? anchor.day : lastDay,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    );
  }

  /// Smallest `k >= 0` whose monthly occurrence is at or after [target].
  /// The month-difference estimate can land at most one month early (when
  /// [target] falls later in its month than the occurrence), so the
  /// correction loop runs at most once.
  int _monthsCatchUp(DateTime anchor, DateTime target) {
    var k = (target.year - anchor.year) * 12 + (target.month - anchor.month);
    if (k < 0) k = 0;
    while (_monthlyOccurrence(anchor, k).isBefore(target)) {
      k++;
    }
    return k;
  }

  DateTime? nextOccurrenceAfter(DateTime from) {
    final dl = deadline;
    if (dl == null) return null;
    final fromUtc = from.toUtc();
    if (!dl.isBefore(fromUtc)) return dl;
    if (recurrence == Recurrence.none) return null;
    final next = _catchUpTo(dl, fromUtc);
    if (recurrenceEndDate != null && next.isAfter(recurrenceEndDate!)) {
      return null;
    }
    return next;
  }

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.deadline == deadline &&
      other.isDone == isDone &&
      other.recurrence == recurrence &&
      other.recurrenceEndDate == recurrenceEndDate &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        deadline,
        isDone,
        recurrence,
        recurrenceEndDate,
        createdAt,
      );
}
