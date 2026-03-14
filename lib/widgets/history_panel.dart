import 'dart:async';
import 'package:flutter/material.dart';
import '../data/astronomy_history.dart';
import '../theme/app_theme.dart';

/// Right sidebar that shows "This Day in History" cycling through
/// 3 astronomical events every 3 minutes with an animated transition.
class HistoryPanel extends StatefulWidget {
  const HistoryPanel({super.key});

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel>
    with SingleTickerProviderStateMixin {
  late final List<AstronomyHistoryEvent> _events;
  int _index = 0;
  Timer? _timer;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final key =
        '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _events = astronomyHistory[key] ?? [];

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..value = 1.0; // start fully visible

    if (_events.length > 1) {
      _timer = Timer.periodic(const Duration(minutes: 3), (_) => _advance());
    }
  }

  void _advance() {
    _animCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _events.length);
      _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.history_edu, size: 11, color: AppColors.textMuted),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'THIS DAY IN HISTORY',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Event tile or fallback
            if (_events.isEmpty)
              _NoEventsCard()
            else
              AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, __) {
                  final opacity = Curves.easeInOut.transform(_animCtrl.value);
                  final slideY = (1.0 - _animCtrl.value) * 8.0;
                  return Transform.translate(
                    offset: Offset(0, slideY),
                    child: Opacity(
                      opacity: opacity,
                      child: _EventTile(event: _events[_index]),
                    ),
                  );
                },
              ),

            // Dot indicators
            if (_events.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _events.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: i == _index ? 12 : 5,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? AppColors.primary
                          : AppColors.textMuted.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
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
          Container(
            height: 1,
            color: AppColors.surfaceBorder,
          ),
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
