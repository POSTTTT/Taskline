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
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.description,
    required DateTime deadline,
    this.isDone = false,
    this.recurrence = Recurrence.none,
    DateTime? createdAt,
  })  : deadline = deadline.toUtc(),
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isDone,
    Recurrence? recurrence,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isDone: isDone ?? this.isDone,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'is_done': isDone ? 1 : 0,
      'recurrence': recurrence.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      deadline: DateTime.parse(map['deadline'] as String),
      isDone: (map['is_done'] as int) == 1,
      recurrence: recurrenceFromString(map['recurrence'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  DateTime? nextOccurrenceAfter(DateTime from) {
    final fromUtc = from.toUtc();
    if (!deadline.isBefore(fromUtc)) return deadline;
    switch (recurrence) {
      case Recurrence.none:
        return null;
      case Recurrence.daily:
        return _advance(deadline, fromUtc, (d) => d.add(const Duration(days: 1)));
      case Recurrence.weekly:
        return _advance(deadline, fromUtc, (d) => d.add(const Duration(days: 7)));
      case Recurrence.monthly:
        return _advance(deadline, fromUtc, (d) => DateTime.utc(
              d.year,
              d.month + 1,
              d.day,
              d.hour,
              d.minute,
              d.second,
              d.millisecond,
              d.microsecond,
            ));
    }
  }

  static DateTime _advance(
    DateTime start,
    DateTime from,
    DateTime Function(DateTime) step,
  ) {
    var next = start;
    while (next.isBefore(from)) {
      next = step(next);
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
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        deadline,
        isDone,
        recurrence,
        createdAt,
      );
}
