import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/celestial_event.dart';
import '../theme/app_theme.dart';
import 'celestial_events_column.dart' show eventColor;

/// A compact two-month calendar (current + next) for the left panel.
/// Pass [allEvents] to show colour-coded indicator dots on event dates.
class MiniCalendar extends StatelessWidget {
  final List<CelestialEvent> allEvents;

  const MiniCalendar({super.key, this.allEvents = const []});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build map from date → list of distinct (color, name) pairs.
    // Deduplicate by name so repeated per-night planet entries each appear
    // as one dot per date (not once per raw event).
    final eventsByDate = <DateTime, List<({Color color, String name})>>{};
    for (final e in allEvents) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      final list = eventsByDate.putIfAbsent(d, () => []);
      if (!list.any((x) => x.name == e.name)) {
        list.add((color: eventColor(e), name: e.name));
      }
    }

    final nextMonth = DateTime(now.year, now.month + 1, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthGrid(
          year: now.year,
          month: now.month,
          today: today,
          eventsByDate: eventsByDate,
        ),
        const SizedBox(height: 14),
        _MonthGrid(
          year: nextMonth.year,
          month: nextMonth.month,
          today: today,
          eventsByDate: eventsByDate,
        ),
      ],
    );
  }
}

// ─── Single month grid ────────────────────────────────────────────────────────

class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime today;
  final Map<DateTime, List<({Color color, String name})>> eventsByDate;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventsByDate,
  });

  @override
  Widget build(BuildContext context) {
    final monthDate = DateTime(year, month, 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(monthDate),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        _WeekdayRow(),
        const SizedBox(height: 2),
        _DaysGrid(
          year: year,
          month: month,
          today: today,
          eventsByDate: eventsByDate,
        ),
      ],
    );
  }
}

// ─── Weekday row ──────────────────────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _labels
          .map((l) => SizedBox(
                width: 20,
                child: Text(
                  l,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ))
          .toList(),
    );
  }
}

// ─── Days grid ────────────────────────────────────────────────────────────────

class _DaysGrid extends StatelessWidget {
  final int year;
  final int month;
  final DateTime today;
  final Map<DateTime, List<({Color color, String name})>> eventsByDate;

  const _DaysGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventsByDate,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon
    final leadingBlanks = firstWeekday - 1;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    final cells = <int?>[
      ...List<int?>.filled(leadingBlanks, null),
      ...List<int?>.generate(daysInMonth, (i) => i + 1),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final weeks = <List<int?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }

    return Column(
      children: weeks
          .map((week) => _WeekRow(
                week: week,
                year: year,
                month: month,
                today: today,
                eventsByDate: eventsByDate,
              ))
          .toList(),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<int?> week;
  final int year;
  final int month;
  final DateTime today;
  final Map<DateTime, List<({Color color, String name})>> eventsByDate;

  const _WeekRow({
    required this.week,
    required this.year,
    required this.month,
    required this.today,
    required this.eventsByDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: week.map((day) {
        if (day == null) return const SizedBox(width: 20, height: 26);

        final date = DateTime(year, month, day);
        final isToday = date == today;
        final dayEvents = eventsByDate[date] ?? [];
        final hasDots = dayEvents.isNotEmpty;

        // Date number or today circle
        final Widget dateWidget = isToday
            ? Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : SizedBox(
                width: 18,
                height: 18,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: hasDots
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight:
                        hasDots ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              );

        // Row of coloured dots (up to 5, 4 px each, 2 px gap)
        final dots = dayEvents.take(5).map((e) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: e.color,
                shape: BoxShape.circle,
              ),
            )).toList();

        Widget cell = SizedBox(
          width: 20,
          height: 26,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              dateWidget,
              if (hasDots) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dots,
                ),
              ],
            ],
          ),
        );

        if (hasDots) {
          final tooltip =
              dayEvents.map((e) => e.name).join('\n');
          cell = Tooltip(message: tooltip, child: cell);
        }

        return cell;
      }).toList(),
    );
  }
}
