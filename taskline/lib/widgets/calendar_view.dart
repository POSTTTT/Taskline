import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'nb.dart';

enum CalendarViewMode { year, month, week }

/// A single occurrence of a task. For non-recurring tasks this matches
/// `task.deadline`; for recurring tasks the calendar generates one entry per
/// occurrence date within the visible window.
class _TaskOccurrence {
  const _TaskOccurrence(this.task, this.date);
  final Task task;
  final DateTime date; // UTC
}

/// Calendar view embedded in HomeScreen's Calendar tab. Supports three zoom
/// levels — Year / Month / Week — switchable via the segmented control at
/// the top. The task list below reflects the visible window: a selected day
/// narrows it to that day; otherwise it shows everything in the year / month
/// / week being viewed.
class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key, required this.onTaskTap});

  final void Function(Task task) onTaskTap;

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  CalendarViewMode _mode = CalendarViewMode.month;
  DateTime _focusedDay = DateTime.now();
  // Null = no day picked, so the list below shows every task in the visible
  // year / month / week. Tap a day in the grid to narrow it down.
  DateTime? _selectedDay;

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _setMode(CalendarViewMode m) {
    setState(() {
      _mode = m;
      _selectedDay = null;
      _focusedDay = DateTime.now();
    });
  }

  List<_TaskOccurrence> _occurrencesIn(
      List<Task> tasks, DateTime start, DateTime end) {
    final out = <_TaskOccurrence>[];
    for (final t in tasks) {
      for (final date in t.occurrencesIn(start, end)) {
        out.add(_TaskOccurrence(t, date));
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  ({DateTime start, DateTime end, String header}) _visibleWindow() {
    switch (_mode) {
      case CalendarViewMode.year:
        return (
          start: DateTime(_focusedDay.year),
          end: DateTime(_focusedDay.year + 1),
          header: 'TASKS IN ${_focusedDay.year}',
        );
      case CalendarViewMode.month:
        return (
          start: DateTime(_focusedDay.year, _focusedDay.month),
          end: DateTime(_focusedDay.year, _focusedDay.month + 1),
          header:
              'TASKS IN ${DateFormat('MMMM yyyy').format(_focusedDay).toUpperCase()}',
        );
      case CalendarViewMode.week:
        final monday =
            _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        final start = _normalize(monday);
        final end = start.add(const Duration(days: 7));
        return (
          start: start,
          end: end,
          header:
              'TASKS THIS WEEK (${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end.subtract(const Duration(days: 1)))})'
                  .toUpperCase(),
        );
    }
  }

  List<_TaskOccurrence> _occurrencesForList(List<Task> all) {
    if (_selectedDay != null && _mode != CalendarViewMode.year) {
      final start = _selectedDay!;
      final end = start.add(const Duration(days: 1));
      return _occurrencesIn(all, start, end);
    }
    final w = _visibleWindow();
    return _occurrencesIn(all, w.start, w.end);
  }

  String _listHeader() {
    if (_selectedDay != null && _mode != CalendarViewMode.year) {
      return DateFormat('EEEE, MMMM d').format(_selectedDay!).toUpperCase();
    }
    return _visibleWindow().header;
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(
        child: Text('Error: $err',
            style:
                AppTextStyles.body.copyWith(color: AppColors.destructive)),
      ),
      data: (allTasks) {
        final occurrences = _occurrencesForList(allTasks);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            NbSegmentedControl<CalendarViewMode>(
              value: _mode,
              options: CalendarViewMode.values,
              labelOf: (m) => switch (m) {
                CalendarViewMode.year => 'YEAR',
                CalendarViewMode.month => 'MONTH',
                CalendarViewMode.week => 'WEEK',
              },
              onChanged: _setMode,
            ),
            const SizedBox(height: 14),
            NbCard(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: switch (_mode) {
                CalendarViewMode.year => _YearGrid(
                    focusedYear: _focusedDay.year,
                    allTasks: allTasks,
                    onYearChange: (year) =>
                        setState(() => _focusedDay = DateTime(year)),
                    onMonthTap: (year, month) {
                      setState(() {
                        _mode = CalendarViewMode.month;
                        _focusedDay = DateTime(year, month);
                        _selectedDay = null;
                      });
                    },
                  ),
                CalendarViewMode.month => _BrutalistCalendar(
                    format: CalendarFormat.month,
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    allTasks: allTasks,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = _normalize(selected);
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => setState(() {
                      _focusedDay = focused;
                      _selectedDay = null;
                    }),
                  ),
                CalendarViewMode.week => _BrutalistCalendar(
                    format: CalendarFormat.week,
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    allTasks: allTasks,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = _normalize(selected);
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => setState(() {
                      _focusedDay = focused;
                      _selectedDay = null;
                    }),
                  ),
              },
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(_listHeader(), style: AppTextStyles.sectionHeader),
            ),
            if (occurrences.isEmpty)
              NbCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                color: AppColors.surfaceVariant,
                child: Center(
                  child: Text('NO TASKS',
                      style: AppTextStyles.subhead
                          .copyWith(fontWeight: FontWeight.w800)),
                ),
              )
            else
              for (var i = 0; i < occurrences.length; i++) ...[
                CalendarTaskTile(
                  task: occurrences[i].task,
                  occurrenceDate: occurrences[i].date,
                  onTap: () => widget.onTaskTap(occurrences[i].task),
                ),
                if (i != occurrences.length - 1)
                  const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

/// Brutalist-themed `table_calendar` shared by month and week modes.
class _BrutalistCalendar extends StatelessWidget {
  const _BrutalistCalendar({
    required this.format,
    required this.focusedDay,
    required this.selectedDay,
    required this.allTasks,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final CalendarFormat format;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<Task> allTasks;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final void Function(DateTime focused) onPageChanged;

  List<Task> _eventsForDay(DateTime day) {
    return allTasks.where((t) => t.occursOn(day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Task>(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2050, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate:
          selectedDay == null ? null : (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      eventLoader: _eventsForDay,
      calendarFormat: format,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      startingDayOfWeek: StartingDayOfWeek.monday,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, _) => format == CalendarFormat.week
            ? 'WEEK OF ${DateFormat('MMM d').format(date).toUpperCase()}'
            : DateFormat('MMMM yyyy').format(date).toUpperCase(),
        titleTextStyle: AppTextStyles.title,
        leftChevronIcon: Icon(Icons.chevron_left,
            color: AppColors.onSurface, size: 28),
        rightChevronIcon: Icon(Icons.chevron_right,
            color: AppColors.onSurface, size: 28),
        leftChevronMargin: EdgeInsets.zero,
        rightChevronMargin: EdgeInsets.zero,
        headerMargin: const EdgeInsets.only(bottom: 8),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTextStyles.footnote.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
        weekendStyle: AppTextStyles.footnote.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: AppColors.destructive,
        ),
      ),
      daysOfWeekHeight: 24,
      rowHeight: 44,
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(3),
        defaultTextStyle: AppTextStyles.body,
        weekendTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.destructive),
        outsideTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.onSurfaceFaint),
        todayDecoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        todayTextStyle: AppTextStyles.body,
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        selectedTextStyle: AppTextStyles.body.copyWith(
            color: AppColors.onPrimary, fontWeight: FontWeight.w700),
      ),
      calendarBuilders: CalendarBuilders<Task>(
        // Replace the bottom dot with a short underline below the day
        // number — clearer than a dot at a glance and stays clear of the
        // selection/today borders.
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: 16,
                height: 2.5,
                color: AppColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Brutalist year view: 12 month cells in a 4×3 grid with task counts.
class _YearGrid extends StatelessWidget {
  const _YearGrid({
    required this.focusedYear,
    required this.allTasks,
    required this.onYearChange,
    required this.onMonthTap,
  });

  final int focusedYear;
  final List<Task> allTasks;
  final void Function(int year) onYearChange;
  final void Function(int year, int month) onMonthTap;

  int _taskCountForMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    var count = 0;
    for (final t in allTasks) {
      count += t.occurrencesIn(start, end).length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left,
                    color: AppColors.onSurface, size: 28),
                onPressed: () => onYearChange(focusedYear - 1),
              ),
              Expanded(
                child: Center(
                  child: Text('$focusedYear', style: AppTextStyles.title),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right,
                    color: AppColors.onSurface, size: 28),
                onPressed: () => onYearChange(focusedYear + 1),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final month = index + 1;
            final count = _taskCountForMonth(focusedYear, month);
            final isCurrent =
                now.year == focusedYear && now.month == month;
            return _MonthCell(
              monthName: DateFormat('MMM').format(DateTime(focusedYear, month)),
              taskCount: count,
              isCurrent: isCurrent,
              onTap: () => onMonthTap(focusedYear, month),
            );
          },
        ),
      ],
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.monthName,
    required this.taskCount,
    required this.isCurrent,
    required this.onTap,
  });

  final String monthName;
  final int taskCount;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.border,
            width: isCurrent ? NbStyles.borderWidth + 1 : NbStyles.borderWidth,
          ),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(monthName.toUpperCase(),
                style: AppTextStyles.subhead
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (taskCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  border: Border.all(
                      color: AppColors.border,
                      width: NbStyles.borderWidth),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '$taskCount',
                  style: AppTextStyles.footnote.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary),
                ),
              )
            else
              Text('—',
                  style: AppTextStyles.footnote
                      .copyWith(color: AppColors.onSurfaceFaint)),
          ],
        ),
      ),
    );
  }
}

/// Calendar-mode task tile: title + countdown badge ("DUE IN 3 DAYS").
class CalendarTaskTile extends ConsumerWidget {
  const CalendarTaskTile({
    super.key,
    required this.task,
    required this.onTap,
    this.occurrenceDate,
  });

  final Task task;
  final VoidCallback onTap;
  // For recurring tasks the calendar passes the specific occurrence date so
  // the countdown reflects "DUE IN X" relative to that occurrence, not the
  // original deadline. Falls back to the task's deadline when omitted.
  final DateTime? occurrenceDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDate = (occurrenceDate ?? task.deadline).toLocal();
    final countdown = formatDueIn(localDate);
    final overdue = localDate.isBefore(DateTime.now()) && !task.isDone;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: NbCard(
        color: task.isDone ? AppColors.surfaceVariant : AppColors.surface,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            NbCheckbox(
              value: task.isDone,
              onChanged: (_) =>
                  ref.read(tasksProvider.notifier).toggleDone(task),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: task.isDone
                          ? AppColors.onSurfaceFaint
                          : AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final badgeFill = task.isDone
                        ? AppColors.surface
                        : overdue
                            ? AppColors.destructive
                            : AppColors.primary;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeFill,
                        border: Border.all(
                            color: AppColors.border,
                            width: NbStyles.borderWidth),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        task.isDone ? 'DONE' : countdown,
                        style: AppTextStyles.footnote.copyWith(
                          color: task.isDone
                              ? AppColors.onSurfaceMuted
                              : NbStyles.foregroundOn(badgeFill),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a duration as "DUE IN 3 DAYS" / "OVERDUE BY 2 HOURS" using a
/// single largest applicable unit. Returns uppercase to suit the theme.
String formatDueIn(DateTime deadline, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = deadline.difference(reference);
  if (diff.isNegative) {
    return 'OVERDUE BY ${_largestUnit(-diff)}';
  }
  return 'DUE IN ${_largestUnit(diff)}';
}

String _largestUnit(Duration d) {
  if (d.inDays >= 365) {
    final years = (d.inDays / 365).floor();
    return '$years ${years == 1 ? 'YEAR' : 'YEARS'}';
  }
  if (d.inDays >= 30) {
    final months = (d.inDays / 30).floor();
    return '$months ${months == 1 ? 'MONTH' : 'MONTHS'}';
  }
  if (d.inDays >= 7) {
    final weeks = (d.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'WEEK' : 'WEEKS'}';
  }
  if (d.inDays >= 1) {
    return '${d.inDays} ${d.inDays == 1 ? 'DAY' : 'DAYS'}';
  }
  if (d.inHours >= 1) {
    return '${d.inHours} ${d.inHours == 1 ? 'HOUR' : 'HOURS'}';
  }
  if (d.inMinutes >= 1) {
    return '${d.inMinutes} ${d.inMinutes == 1 ? 'MINUTE' : 'MINUTES'}';
  }
  return 'A MOMENT';
}
