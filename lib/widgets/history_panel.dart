import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _HistoryDetailDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            // Year badge + open icon row
            Row(
              children: [
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
                const Spacer(),
                const Icon(Icons.open_in_new,
                    size: 12, color: AppColors.textMuted),
              ],
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
      ),
    );
  }
}

// ─── Detail popup dialog ─────────────────────────────────────────────────────

class _HistoryDetailDialog extends StatelessWidget {
  final AstronomyHistoryEvent event;
  const _HistoryDetailDialog({required this.event});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String get _wikiUrl {
    final query = Uri.encodeComponent('${event.title} ${event.year}');
    return 'https://en.wikipedia.org/w/index.php?search=$query';
  }

  String get _googleUrl {
    final query = Uri.encodeComponent('${event.title} ${event.year} astronomy');
    return 'https://www.google.com/search?q=$query';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: year badge + close button
              Row(
                children: [
                  const Icon(Icons.history_edu,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                event.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Divider
              Container(height: 1, color: AppColors.surfaceBorder),
              const SizedBox(height: 12),

              // Detail text
              Text(
                event.detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),

              // Learn More section
              const Text(
                'LEARN MORE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _LinkButton(
                icon: Icons.menu_book_outlined,
                label: 'Search Wikipedia',
                onTap: () => _launch(_wikiUrl),
              ),
              const SizedBox(height: 6),
              _LinkButton(
                icon: Icons.search,
                label: 'Search Google',
                onTap: () => _launch(_googleUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.primary.withAlpha(50), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new, size: 11, color: AppColors.primary),
          ],
        ),
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
