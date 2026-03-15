import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/celestial_event.dart';
import '../theme/app_theme.dart';

/// Vertical stacked list of upcoming celestial event cards.
/// Used in the left sidebar panel of the forecast screen.
class CelestialEventsColumn extends StatelessWidget {
  final List<CelestialEvent> events;

  const CelestialEventsColumn({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    // Collapse all events with the same name into a single card,
    // regardless of whether they are consecutive in the sorted list
    // (handles repeated per-night planet events like "Jupiter Visible" × 42).
    final nameMap = <String, ({CelestialEvent event, int count})>{};
    for (final e in events) {
      if (nameMap.containsKey(e.name)) {
        nameMap[e.name] = (event: nameMap[e.name]!.event, count: nameMap[e.name]!.count + 1);
      } else {
        nameMap[e.name] = (event: e, count: 1);
      }
    }
    final grouped = nameMap.values.toList()
      ..sort((a, b) => a.event.date.compareTo(b.event.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            children: const [
              Icon(Icons.event_note, size: 10, color: AppColors.textMuted),
              SizedBox(width: 4),
              Text(
                'CELESTIAL EVENTS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        ...grouped.map((g) => _EventCard(event: g.event, nightCount: g.count)),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Unified colour lookup for any [CelestialEvent] — used by both event tiles
/// and the mini-calendar so colours stay in sync from a single source of truth.
Color eventColor(CelestialEvent event) {
  switch (event.type) {
    case CelestialEventType.meteorShower:
      return const Color(0xFF40C4FF); // sky blue
    case CelestialEventType.aurora:
      return const Color(0xFF69F0AE); // mint green
    case CelestialEventType.moon:
      return AppColors.moonGold;      // gold
    case CelestialEventType.orbital:
      return const Color(0xFF82B1FF); // periwinkle blue
    case CelestialEventType.planet:
      final n = event.name;
      if (n.startsWith('Mercury')) return const Color(0xFF90A4AE); // steel-blue grey
      if (n.startsWith('Venus'))   return const Color(0xFFFF80AB); // hot pink
      if (n.startsWith('Mars'))    return const Color(0xFFEF5350); // vivid red
      if (n.startsWith('Jupiter')) return const Color(0xFFFF8F00); // deep amber
      if (n.startsWith('Saturn'))  return const Color(0xFFCE93D8); // lavender-purple
      return AppColors.primary;
  }
}

// Legacy alias kept so any future callers still compile.
Color planetColor(String eventName) =>
    eventColor(CelestialEvent(
      type: CelestialEventType.planet,
      name: eventName,
      date: DateTime.now(),
      description: '',
    ));

class _EventCard extends StatelessWidget {
  final CelestialEvent event;
  final int nightCount;
  const _EventCard({required this.event, this.nightCount = 1});

  Color get _accentColor => eventColor(event);

  IconData get _icon {
    switch (event.type) {
      case CelestialEventType.meteorShower:
        return Icons.auto_awesome;
      case CelestialEventType.aurora:
        return Icons.wb_twilight;
      case CelestialEventType.planet:
        return Icons.circle_outlined;
      case CelestialEventType.moon:
        return Icons.nightlight_round;
      case CelestialEventType.orbital:
        return Icons.rotate_90_degrees_ccw;
    }
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = d.difference(today).inDays;
    if (diff == 0) return 'Tonight';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 6) return 'In $diff days';
    return DateFormat('d MMM').format(date);
  }

  String get _description {
    if (nightCount > 1) {
      // Extract planet name from e.g. "Jupiter Visible" → "Jupiter"
      final planet = event.name.replaceAll(' Visible', '');
      return '$planet above 10° during dark window — $nightCount nights';
    }
    return event.description;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Tooltip(
      message: event.description,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: accent.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withAlpha(90)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left accent bar
            Container(
              width: 3,
              height: 60,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_icon, size: 9, color: accent),
                        const SizedBox(width: 3),
                        Text(
                          _dateLabel(event.date),
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 8,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
