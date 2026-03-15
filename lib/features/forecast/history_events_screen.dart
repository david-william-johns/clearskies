import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/astronomy_history.dart';
import '../../theme/app_theme.dart';

class HistoryEventsScreen extends StatefulWidget {
  const HistoryEventsScreen({super.key});

  @override
  State<HistoryEventsScreen> createState() => _HistoryEventsScreenState();
}

class _HistoryEventsScreenState extends State<HistoryEventsScreen> {
  DateTime _selectedDate = DateTime.now();

  List<AstronomyHistoryEvent> get _events {
    final key =
        '${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    return astronomyHistory[key] ?? [];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2000, 12, 31),
      helpText: 'Select a date',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.background,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    final dateLabel = DateFormat('d MMMM').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Row(
          children: [
            Icon(Icons.history_edu, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'History Events',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        foregroundColor: AppColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Date picker ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT DATE',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar, size: 14),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Section header ───────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'THIS DAY IN HISTORY',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '— $dateLabel',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Event tiles ──────────────────────────────────────────────────
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      color: AppColors.textMuted, size: 32),
                  SizedBox(height: 10),
                  Text(
                    'No astronomical history records\nfor this date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            )
          else
            ...events.expand((e) => [
                  _HistoryEventCard(event: e),
                  const SizedBox(height: 12),
                ]),
        ],
      ),
    );
  }
}

// ─── Event card (replicates HistoryPanel._EventTile style) ───────────────────

class _HistoryEventCard extends StatelessWidget {
  final AstronomyHistoryEvent event;
  const _HistoryEventCard({required this.event});

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.open_in_new,
                    size: 13, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.surfaceBorder),
            const SizedBox(height: 8),
            Text(
              event.detail,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail dialog (reuses history_panel dialog logic) ───────────────────────

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
    final query =
        Uri.encodeComponent('${event.title} ${event.year} astronomy');
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
              Row(
                children: [
                  const Icon(Icons.history_edu,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
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
              Container(height: 1, color: AppColors.surfaceBorder),
              const SizedBox(height: 12),
              Text(
                event.detail,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
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
          border: Border.all(
              color: AppColors.primary.withAlpha(50), width: 0.8),
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
            const Icon(Icons.open_in_new,
                size: 11, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
