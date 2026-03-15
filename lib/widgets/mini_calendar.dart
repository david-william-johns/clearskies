import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/celestial_event.dart';
import '../theme/app_theme.dart';

/// A compact two-month calendar (current + next) for the left panel.
/// Pass [allEvents] to show colour-coded indicator dots on event dates.
class MiniCalendar extends StatelessWidget {
  final List<CelestialEvent> allEvents;

  const MiniCalendar({super.key, this.allEvents = const []});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build map from date → event type (first event wins for dot colour)
    final eventDates = <DateTime, CelestialEventType>{};
    for (final e in allEvents) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      eventDates.putIfAbsent(d, () => e.type);
    }

    // Next month
    final nextMonth = DateTime(now.year, now.month + 1, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthGrid(
          year: now.year,
          month: now.month,
          today: today,
          eventDates: eventDates,
        ),
        const SizedBox(height: 14),
        _MonthGrid(
          year: nextMonth.year,
          month: nextMonth.month,
          today: today,
          eventDates: eventDates,
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
  final Map<DateTime, CelestialEventType> eventDates;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventDates,
  });

  @override
  Widget build(BuildContext context) {
    final monthDate = DateTime(year, month, 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Month + year header
        Text(
          DateFormat('MMMM yyyy').format(monthDate),
          style: const TextStyle(
            color: AppColors.textSecondary,
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
          eventDates: eventDates,
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
  final Map<DateTime, CelestialEventType> eventDates;

  const _DaysGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventDates,
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
    while (cells.length % 7 != 0) { cells.add(null); }

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
  final Map<DateTime, CelestialEventType> eventDates;

  const _WeekRow({
    required this.week,
    required this.year,
    required this.month,
    required this.today,
    required this.eventDates,
  });

  Color _dotColor(CelestialEventType type) {
    switch (type) {
      case CelestialEventType.meteorShower:
        return const Color(0xFFFFAB40);
      case CelestialEventType.aurora:
        return const Color(0xFF00E676);
      case CelestialEventType.planet:
        return AppColors.primary;
      case CelestialEventType.moon:
        return AppColors.moonGold;
      case CelestialEventType.orbital:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: week.map((day) {
        if (day == null) return const SizedBox(width: 20, height: 22);

        final date = DateTime(year, month, day);
        final isToday = date == today;
        final eventType = eventDates[date];

        Widget dayCell;
        if (isToday) {
          dayCell = Container(
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
          );
        } else if (eventType != null) {
          dayCell = Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: _dotColor(eventType),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else {
          dayCell = SizedBox(
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
        }

        Widget cell = SizedBox(
          width: 20,
          height: 22,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              dayCell,
              const SizedBox(height: 4),
            ],
          ),
        );

        if (eventType != null) {
          final eventName = eventDates.keys
              .where((k) => k == date)
              .map((_) => eventType.name)
              .firstOrNull;
          cell = Tooltip(
            message: eventName ?? eventType.name,
            child: cell,
          );
        }

        return cell;
      }).toList(),
    );
  }
}
