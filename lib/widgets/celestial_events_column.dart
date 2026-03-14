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
        ...events.map((e) => _EventCard(event: e)),
        const SizedBox(height: 8),
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
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(190),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
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
                      event.description,
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
