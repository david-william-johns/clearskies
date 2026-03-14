import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/celestial_event.dart';
import '../../theme/app_theme.dart';

/// Horizontal scrollable bar of upcoming celestial event cards.
/// Inserted between the legend and the day tiles in the forecast screen.
class CelestialEventsBar extends StatelessWidget {
  final List<CelestialEvent> events;

  const CelestialEventsBar({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
          child: Row(
            children: [
              const Icon(Icons.event_note, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              const Text(
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
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: events.length,
            itemBuilder: (context, i) => _EventCard(event: events[i]),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final CelestialEvent event;
  const _EventCard({required this.event});

  Color get _accentColor {
    switch (event.type) {
      case CelestialEventType.meteorShower:
        return const Color(0xFFFFAB40); // amber-orange
      case CelestialEventType.aurora:
        return const Color(0xFF00E676); // green
      case CelestialEventType.planet:
        return AppColors.primary; // cyan
      case CelestialEventType.moon:
        return AppColors.moonGold;
      case CelestialEventType.orbital:
        return AppColors.textSecondary;
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Tooltip(
      message: event.description,
      child: Container(
        width: 138,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(190),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(_icon, size: 10, color: accent),
                        const SizedBox(width: 3),
                        Text(
                          _dateLabel(event.date),
                          style: TextStyle(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      event.description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 8,
                      ),
                      maxLines: 1,
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
