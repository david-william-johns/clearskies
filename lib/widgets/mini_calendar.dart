import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/celestial_event.dart';
import '../theme/app_theme.dart';

/// A compact monthly calendar, week starts Monday (ISO), for the left panel.
/// Pass [orbitalEvents] to show indicator dots on event dates.
class MiniCalendar extends StatelessWidget {
  final List<CelestialEvent> orbitalEvents;

  const MiniCalendar({super.key, this.orbitalEvents = const []});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a set of dates that have orbital events (for O(1) lookup)
    final eventDates = <DateTime, String>{};
    for (final e in orbitalEvents) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      eventDates[d] = e.name;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(now: now),
        const SizedBox(height: 6),
        _WeekdayRow(),
        const SizedBox(height: 2),
        _DaysGrid(
          year: now.year,
          month: now.month,
          today: today,
          eventDates: eventDates,
        ),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DateTime now;
  const _Header({required this.now});

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('MMMM yyyy').format(now),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─── Weekday row: M T W T F S S ──────────────────────────────────────────────

class _WeekdayRow extends StatelessWidget {
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _labels
          .map((l) => SizedBox(
                width: 18,
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
  final Map<DateTime, String> eventDates;

  const _DaysGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventDates,
  });

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun
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
                eventDates: eventDates,
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
  final Map<DateTime, String> eventDates;

  const _WeekRow({
    required this.week,
    required this.year,
    required this.month,
    required this.today,
    required this.eventDates,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: week.map((day) {
        if (day == null) {
          return const SizedBox(width: 18, height: 22);
        }
        final date = DateTime(year, month, day);
        final isToday = date == today;
        final eventName = eventDates[date];
        final hasEvent = eventName != null;

        Widget dayCell = isToday
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
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                  textAlign: TextAlign.center,
                ),
              );

        // Stack with optional event dot below
        Widget cell = SizedBox(
          width: 18,
          height: 22,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              dayCell,
              if (hasEvent)
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 4),
            ],
          ),
        );

        if (hasEvent) {
          cell = Tooltip(
            message: eventName,
            child: cell,
          );
        }

        return cell;
      }).toList(),
    );
  }
}
