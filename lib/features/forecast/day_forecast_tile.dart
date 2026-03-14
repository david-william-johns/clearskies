import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/day_forecast.dart';
import '../../models/hourly_slot.dart';
import '../../theme/app_theme.dart';
import '../../widgets/night_weather_icon.dart';
import 'clear_sky_score_badge.dart';
import 'hourly_conditions_grid.dart';

class DayForecastTile extends StatefulWidget {
  final DayForecast forecast;
  final bool initiallyExpanded;

  const DayForecastTile({
    super.key,
    required this.forecast,
    this.initiallyExpanded = false,
  });

  @override
  State<DayForecastTile> createState() => _DayForecastTileState();
}

class _DayForecastTileState extends State<DayForecastTile> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final f = widget.forecast;
    final score = f.clearSkyScore;
    final scoreColor = AppColors.scoreColor(score);
    final isToday = _isToday(f.date);

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.surfaceElevated.withAlpha(205)
              : AppColors.surface.withAlpha(190),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? AppColors.primary.withAlpha(80)
                : AppColors.surfaceBorder,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            _CollapsedHeader(forecast: f, score: score, scoreColor: scoreColor, isToday: isToday, expanded: _expanded),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              sizeCurve: Curves.easeInOutCubic,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _ExpandedBody(forecast: f)
                  .animate()
                  .fadeIn(duration: 300.ms, curve: Curves.easeIn),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

// ─── Collapsed header ────────────────────────────────────────────────────────

class _CollapsedHeader extends StatelessWidget {
  final DayForecast forecast;
  final int score;
  final Color scoreColor;
  final bool isToday;
  final bool expanded;

  const _CollapsedHeader({
    required this.forecast,
    required this.score,
    required this.scoreColor,
    required this.isToday,
    required this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final dayLabel = isToday
        ? 'TODAY'
        : DateFormat('EEE').format(f.date.toLocal()).toUpperCase();
    final dateLabel = DateFormat('d MMM').format(f.date.toLocal());
    final duskStr = _timeStr(f.astronomicalDusk);
    final darkHours = f.darkDuration.inMinutes / 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Day + date
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: isToday ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Cloud cover mini-bar + percentage
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cloud bar
                _MiniCloudBar(pct: f.bestCloudCover),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.cloud_outlined,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      '${f.bestCloudCover}% cloud',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.nightlight_round,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(
                      'Dusk $duskStr',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Moon + dark hours
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Text(
                    f.moonPhaseEmoji,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${f.moonIlluminationPct}%',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
              Text(
                '${darkHours.toStringAsFixed(1)}h dark',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(width: 8),

          // Night weather animation
          NightWeatherIcon(forecast: f),

          const SizedBox(width: 8),

          // Score badge + chevron
          Column(
            children: [
              ClearSkyScoreBadge(score: score),
              const SizedBox(height: 2),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeStr(DateTime t) => DateFormat('HH:mm').format(t.toLocal());
}

// ─── Expanded body ───────────────────────────────────────────────────────────

class _ExpandedBody extends StatelessWidget {
  final DayForecast forecast;
  const _ExpandedBody({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 14, endIndent: 14),
        // Dark window summary
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: _DarkWindowSummary(forecast: f),
        ),
        // Hourly grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: HourlyConditionsGrid(slots: f.darkHourSlots),
        ),
        const SizedBox(height: 12),
        // Cloud cover chart
        if (f.darkHourSlots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: _CloudCoverChart(slots: f.darkHourSlots),
          ),
        // Moon info
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: _MoonInfo(forecast: f),
        ),
      ],
    );
  }
}

class _DarkWindowSummary extends StatelessWidget {
  final DayForecast forecast;
  const _DarkWindowSummary({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final dusk = _fmt(f.astronomicalDusk);
    final dawn = _fmt(f.astronomicalDawn);
    final h = f.darkDuration.inHours;
    final m = f.darkDuration.inMinutes % 60;

    return Row(
      children: [
        _InfoChip(
          icon: Icons.nightlight_outlined,
          label: 'Dark',
          value: '$dusk – $dawn ($h h ${m}m)',
        ),
        const SizedBox(width: 12),
        ClearSkyScoreBadge(score: f.clearSkyScore, large: true),
      ],
    );
  }

  String _fmt(DateTime t) => DateFormat('HH:mm').format(t.toLocal());
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.5)),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

// ─── Cloud cover chart ───────────────────────────────────────────────────────

class _CloudCoverChart extends StatelessWidget {
  final List<HourlySlot> slots;
  const _CloudCoverChart({required this.slots});

  @override
  Widget build(BuildContext context) {
    final spots = slots.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.cloudCoverTotal.toDouble());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CLOUD COVER',
          style: TextStyle(
              color: AppColors.textMuted, fontSize: 9, letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 60,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: AppColors.surfaceBorder,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      '${v.round()}%',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 8),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (slots.length / 4).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final idx = v.round();
                      if (idx < 0 || idx >= slots.length) return const SizedBox();
                      return Text(
                        DateFormat('HH:mm').format(slots[idx].time.toLocal()),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 8),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.primary,
                  barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withAlpha(30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Moon info ───────────────────────────────────────────────────────────────

class _MoonInfo extends StatelessWidget {
  final DayForecast forecast;
  const _MoonInfo({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final riseStr = f.moonRise != null ? _fmt(f.moonRise!) : '--:--';
    final setStr = f.moonSet != null ? _fmt(f.moonSet!) : '--:--';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(185),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Text(f.moonPhaseEmoji,
              style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.moonPhaseName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  '${f.moonIlluminationPct}% illuminated',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MoonTime(icon: Icons.arrow_upward, label: 'Rise', time: riseStr),
              const SizedBox(height: 2),
              _MoonTime(icon: Icons.arrow_downward, label: 'Set', time: setStr),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) => DateFormat('HH:mm').format(t.toLocal());
}

class _MoonTime extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  const _MoonTime({required this.icon, required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.moonGold),
        const SizedBox(width: 3),
        Text(
          '$label $time',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

// ─── Mini cloud bar (for collapsed) ─────────────────────────────────────────

class _MiniCloudBar extends StatelessWidget {
  final int pct;
  const _MiniCloudBar({required this.pct});

  Color get _color {
    if (pct <= 20) return AppColors.scoreExcellent;
    if (pct <= 40) return AppColors.scoreGood;
    if (pct <= 60) return AppColors.scoreFair;
    if (pct <= 80) return AppColors.scoreAmber;
    return AppColors.scorePoor;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      return Stack(
        children: [
          Container(
            height: 4,
            width: w,
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            height: 4,
            width: w * pct / 100,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      );
    });
  }
}
