import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/celestial_event.dart';
import '../theme/app_theme.dart';
import 'celestial_events_column.dart' show planetColor;

/// A compact two-month calendar (current + next) for the left panel.
/// Pass [allEvents] to show colour-coded indicator dots on event dates.
class MiniCalendar extends StatelessWidget {
  final List<CelestialEvent> allEvents;

  const MiniCalendar({super.key, this.allEvents = const []});

  Color _eventColor(CelestialEvent e) {
    switch (e.type) {
      case CelestialEventType.meteorShower:
        return const Color(0xFFFFAB40);
      case CelestialEventType.aurora:
        return const Color(0xFF00E676);
      case CelestialEventType.planet:
        return planetColor(e.name);
      case CelestialEventType.moon:
        return AppColors.moonGold;
      case CelestialEventType.orbital:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build map from date → colour (first event per date wins)
    final eventColors = <DateTime, Color>{};
    for (final e in allEvents) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      eventColors.putIfAbsent(d, () => _eventColor(e));
    }

    // Build map from date → tooltip name (first event per date wins)
    final eventTooltips = <DateTime, String>{};
    for (final e in allEvents) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      eventTooltips.putIfAbsent(d, () => e.name);
    }

    // Determine which dates belong to multi-day events
    // (events where the same name appears on more than one date)
    final nameDates = <String, Set<DateTime>>{};
    for (final e in allEvents) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      nameDates.putIfAbsent(e.name, () => {}).add(d);
    }
    final multiDayDates = <DateTime>{};
    for (final entry in nameDates.entries) {
      if (entry.value.length > 1) multiDayDates.addAll(entry.value);
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
          eventColors: eventColors,
          eventTooltips: eventTooltips,
          multiDayDates: multiDayDates,
        ),
        const SizedBox(height: 14),
        _MonthGrid(
          year: nextMonth.year,
          month: nextMonth.month,
          today: today,
          eventColors: eventColors,
          eventTooltips: eventTooltips,
          multiDayDates: multiDayDates,
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
  final Map<DateTime, Color> eventColors;
  final Map<DateTime, String> eventTooltips;
  final Set<DateTime> multiDayDates;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventColors,
    required this.eventTooltips,
    required this.multiDayDates,
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
          eventColors: eventColors,
          eventTooltips: eventTooltips,
          multiDayDates: multiDayDates,
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
  final Map<DateTime, Color> eventColors;
  final Map<DateTime, String> eventTooltips;
  final Set<DateTime> multiDayDates;

  const _DaysGrid({
    required this.year,
    required this.month,
    required this.today,
    required this.eventColors,
    required this.eventTooltips,
    required this.multiDayDates,
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
                eventColors: eventColors,
                eventTooltips: eventTooltips,
                multiDayDates: multiDayDates,
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
  final Map<DateTime, Color> eventColors;
  final Map<DateTime, String> eventTooltips;
  final Set<DateTime> multiDayDates;

  const _WeekRow({
    required this.week,
    required this.year,
    required this.month,
    required this.today,
    required this.eventColors,
    required this.eventTooltips,
    required this.multiDayDates,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: week.map((day) {
        if (day == null) return const SizedBox(width: 20, height: 22);

        final date = DateTime(year, month, day);
        final isToday = date == today;
        final dotColor = eventColors[date];
        final isMultiDay = dotColor != null && multiDayDates.contains(date);
        final tooltipMsg = eventTooltips[date] ?? '';

        Widget dayCell;

        if (isToday) {
          // Today: cyan circle, takes priority
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
        } else if (dotColor != null && !isMultiDay) {
          // Single-day event: filled coloured circle with date in black
          dayCell = Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: dotColor,
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
        } else if (dotColor != null && isMultiDay) {
          // Multi-day event: small dot above the date number
          dayCell = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                '$day',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
          child: Center(child: dayCell),
        );

        if (dotColor != null) {
          cell = Tooltip(
            message: tooltipMsg,
            child: cell,
          );
        }

        return cell;
      }).toList(),
    );
  }
}
