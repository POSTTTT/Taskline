import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'nb.dart';

enum CalendarViewMode { year, month, week }

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

  bool _taskIsIn(Task t, DateTime start, DateTime end) {
    final d = t.deadline.toLocal();
    return !d.isBefore(start) && d.isBefore(end);
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

  List<Task> _tasksForList(List<Task> all) {
    if (_selectedDay != null && _mode != CalendarViewMode.year) {
      final start = _selectedDay!;
      final end = start.add(const Duration(days: 1));
      return all.where((t) => _taskIsIn(t, start, end)).toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));
    }
    final w = _visibleWindow();
    return all.where((t) => _taskIsIn(t, w.start, w.end)).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
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
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(
        child: Text('Error: $err',
            style:
                AppTextStyles.body.copyWith(color: AppColors.destructive)),
      ),
      data: (allTasks) {
        final tasksForList = _tasksForList(allTasks);

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
                      // Navigating to a different month/week — drop the
                      // selection so the list reflects the new window.
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
                      // Navigating to a different month/week — drop the
                      // selection so the list reflects the new window.
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
            if (tasksForList.isEmpty)
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
              for (var i = 0; i < tasksForList.length; i++) ...[
                CalendarTaskTile(
                  task: tasksForList[i],
                  onTap: () => widget.onTaskTap(tasksForList[i]),
                ),
                if (i != tasksForList.length - 1)
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
    final target = DateTime(day.year, day.month, day.day);
    return allTasks.where((t) {
      final d = t.deadline.toLocal();
      return DateTime(d.year, d.month, d.day) == target;
    }).toList();
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
        leftChevronIcon: const Icon(Icons.chevron_left,
            color: AppColors.onSurface, size: 28),
        rightChevronIcon: const Icon(Icons.chevron_right,
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
          border: Border.all(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius: BorderRadius.circular(4),
        ),
        todayTextStyle: AppTextStyles.body,
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(
              color: AppColors.border, width: NbStyles.borderWidth),
          borderRadius: BorderRadius.circular(4),
        ),
        selectedTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.onSurface),
        markerDecoration: const BoxDecoration(
          color: AppColors.border,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
        markerSize: 5,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1.5),
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
    return allTasks.where((t) {
      final d = t.deadline.toLocal();
      return d.year == year && d.month == month;
    }).length;
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
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.onSurface, size: 28),
                onPressed: () => onYearChange(focusedYear - 1),
              ),
              Expanded(
                child: Center(
                  child: Text('$focusedYear', style: AppTextStyles.title),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
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
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(monthName.toUpperCase(),
                style: AppTextStyles.subhead
                    .copyWith(fontWeight: FontWeight.w900)),
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
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '$taskCount',
                  style: AppTextStyles.footnote
                      .copyWith(fontWeight: FontWeight.w900),
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
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localDeadline = task.deadline.toLocal();
    final countdown = formatDueIn(localDeadline);
    final overdue = localDeadline.isBefore(DateTime.now()) && !task.isDone;

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
                      fontSize: 17,
                      color: task.isDone
                          ? AppColors.onSurfaceFaint
                          : AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: task.isDone
                          ? AppColors.surface
                          : overdue
                              ? AppColors.destructive
                              : AppColors.primary,
                      border: Border.all(
                          color: AppColors.border,
                          width: NbStyles.borderWidth),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      task.isDone ? 'DONE' : countdown,
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
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
