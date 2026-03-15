import 'package:flutter/material.dart';
import '../data/astronomy_history.dart';
import '../theme/app_theme.dart';

/// Right sidebar that shows "This Day in History" with all 3 astronomical
/// events for today displayed as separate stacked tiles.
class HistoryPanel extends StatelessWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final key =
        '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final events = astronomyHistory[key] ?? [];

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.history_edu, size: 18, color: AppColors.primary),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'THIS DAY IN HISTORY',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Event tiles or fallback
            if (events.isEmpty)
              _NoEventsCard()
            else
              ...events.expand((e) => [
                    _EventTile(event: e),
                    const SizedBox(height: 8),
                  ]),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final AstronomyHistoryEvent event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppColors.primary.withAlpha(60), width: 0.8),
            ),
            child: Text(
              '${event.year}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            event.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Divider
          Container(height: 1, color: AppColors.surfaceBorder),
          const SizedBox(height: 6),

          // Detail
          Text(
            event.detail,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoEventsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, color: AppColors.textMuted, size: 24),
          SizedBox(height: 8),
          Text(
            'No records found\nfor this date.',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 10, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
