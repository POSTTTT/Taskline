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
  final DateTime deadline;
  final bool isDone;
  final Recurrence recurrence;
  final DateTime? recurrenceEndDate;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    required DateTime deadline,
    this.isDone = false,
    this.recurrence = Recurrence.none,
    DateTime? recurrenceEndDate,
    DateTime? createdAt,
  })  : deadline = deadline.toUtc(),
        recurrenceEndDate = recurrenceEndDate?.toUtc(),
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isDone,
    Recurrence? recurrence,
    Object? recurrenceEndDate = _sentinel,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
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
      'deadline': deadline.toIso8601String(),
      'is_done': isDone ? 1 : 0,
      'recurrence': recurrence.name,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    final endRaw = map['recurrence_end_date'] as String?;
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: DateTime.parse(map['deadline'] as String),
      isDone: (map['is_done'] as int) == 1,
      recurrence: recurrenceFromString(map['recurrence'] as String),
      recurrenceEndDate: endRaw == null ? null : DateTime.parse(endRaw),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Returns true if a recurrence (or the original deadline) lands on `day`
  /// in local time. Used by the calendar to mark days and filter the list.
  bool occursOn(DateTime day) {
    final localDay = DateTime(day.year, day.month, day.day);
    final localDeadline = deadline.toLocal();
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
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final effectiveEnd = recurrenceEndDate != null &&
            recurrenceEndDate!.isBefore(endUtc)
        ? DateTime.utc(recurrenceEndDate!.year, recurrenceEndDate!.month,
                recurrenceEndDate!.day)
            .add(const Duration(days: 1)) // include the end date itself
        : endUtc;

    if (recurrence == Recurrence.none) {
      if (!deadline.isBefore(startUtc) && deadline.isBefore(endUtc)) {
        yield deadline;
      }
      return;
    }

    var current = deadline;
    while (current.isBefore(startUtc)) {
      current = _step(current);
    }
    while (current.isBefore(effectiveEnd)) {
      yield current;
      current = _step(current);
    }
  }

  DateTime _step(DateTime d) {
    switch (recurrence) {
      case Recurrence.none:
        return d;
      case Recurrence.daily:
        return d.add(const Duration(days: 1));
      case Recurrence.weekly:
        return d.add(const Duration(days: 7));
      case Recurrence.monthly:
        return DateTime.utc(
          d.year,
          d.month + 1,
          d.day,
          d.hour,
          d.minute,
          d.second,
          d.millisecond,
          d.microsecond,
        );
    }
  }

  DateTime? nextOccurrenceAfter(DateTime from) {
    final fromUtc = from.toUtc();
    if (!deadline.isBefore(fromUtc)) return deadline;
    if (recurrence == Recurrence.none) return null;
    var next = deadline;
    while (next.isBefore(fromUtc)) {
      next = _step(next);
    }
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
