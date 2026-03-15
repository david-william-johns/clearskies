import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import '../../models/day_forecast.dart';
import '../../models/hourly_slot.dart';
import '../../models/location.dart';
import '../../theme/app_theme.dart';
import '../../widgets/night_weather_icon.dart';
import 'clear_sky_score_badge.dart';
import 'hourly_conditions_grid.dart';

class DayForecastTile extends StatefulWidget {
  final DayForecast forecast;
  final AppLocation location;
  final bool initiallyExpanded;

  const DayForecastTile({
    super.key,
    required this.forecast,
    required this.location,
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
            _CollapsedHeader(
                forecast: f,
                score: score,
                scoreColor: scoreColor,
                isToday: isToday,
                expanded: _expanded),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 350),
              sizeCurve: Curves.easeInOutCubic,
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _ExpandedBody(
                      forecast: f, location: widget.location)
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
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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

  // Returns a human-readable night condition label matching NightWeatherIcon logic.
  String _conditionLabel(DayForecast f) {
    if (f.darkHourSlots.isEmpty) return 'Clear';
    final n = f.darkHourSlots.length;
    final avgCloud =
        f.darkHourSlots.map((s) => s.cloudCoverTotal).reduce((a, b) => a + b) ~/
            n;
    final avgPrecip =
        f.darkHourSlots
            .map((s) => s.precipitationProbability)
            .reduce((a, b) => a + b) ~/
        n;
    final avgTemp =
        f.darkHourSlots.map((s) => s.temperature).reduce((a, b) => a + b) / n;
    if (avgPrecip > 40 && avgTemp <= 1.0) return 'Snowy';
    if (avgPrecip > 40) return 'Rainy';
    if (avgCloud > 80) return 'Overcast';
    if (avgCloud > 50) return 'Mostly Cloudy';
    if (avgCloud > 20) return 'Partly Cloudy';
    return 'Clear';
  }

  String _nightIconTooltip(DayForecast f) {
    final condition = _conditionLabel(f);
    final riseStr =
        f.moonRise != null ? DateFormat('HH:mm').format(f.moonRise!.toLocal()) : '--:--';
    final setStr =
        f.moonSet != null ? DateFormat('HH:mm').format(f.moonSet!.toLocal()) : '--:--';
    return 'Night condition: $condition\n'
        'Avg cloud cover: ${f.bestCloudCover}%\n'
        'Avg temperature: ${f.avgTemperature.toStringAsFixed(1)}°C\n'
        'Avg wind: ${f.avgWindKmh.round()} km/h\n'
        'Precipitation chance: ${f.maxPrecipPct}%\n'
        'Moon: ${f.moonPhaseName} — ${f.moonIlluminationPct}% illuminated\n'
        'Moonrise: $riseStr  ·  Moonset: $setStr';
  }

  String _scoreTooltip(DayForecast f) {
    final seeing = f.avgSeeing > 0 ? '${f.avgSeeing.toStringAsFixed(1)}/5' : 'N/A';
    return 'Clear Sky Score: ${f.clearSkyScore}/100\n'
        'Composite score for telescope observing conditions\n\n'
        'Cloud cover (40%): ${f.bestCloudCover}%\n'
        'Seeing quality (25%): $seeing\n'
        'Moon illumination (10%): ${f.moonIlluminationPct}%\n'
        'Humidity (3%): ${f.avgHumidity}%\n'
        'Wind speed (2%): ${f.avgWindKmh.round()} km/h';
  }

  String _moonTooltip(DayForecast f) {
    final riseStr =
        f.moonRise != null ? DateFormat('HH:mm').format(f.moonRise!.toLocal()) : '--:--';
    final setStr =
        f.moonSet != null ? DateFormat('HH:mm').format(f.moonSet!.toLocal()) : '--:--';
    return '${f.moonPhaseName}\n'
        '${f.moonIlluminationPct}% illuminated\n'
        'Rises: $riseStr  ·  Sets: $setStr';
  }

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final dayLabel = isToday
        ? 'TODAY'
        : DateFormat('EEE').format(f.date.toLocal()).toUpperCase();
    final dateLabel = DateFormat('d MMM').format(f.date.toLocal());
    final duskStr = DateFormat('HH:mm').format(f.astronomicalDusk.toLocal());

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

          // Weather chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: cloud, temp, wind, precip
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _WeatherChip(
                        icon: Icons.cloud_outlined,
                        label: '${f.bestCloudCover}% cloud cover'),
                    _WeatherChip(
                        icon: Icons.thermostat,
                        label:
                            '${f.avgTemperature.toStringAsFixed(1)}°C'),
                    _WeatherChip(
                        icon: Icons.air,
                        label: '${f.avgWindKmh.round()} km/h'),
                    _WeatherChip(
                        icon: Icons.water_drop_outlined,
                        label: '${f.maxPrecipPct}% precip'),
                  ],
                ),
                const SizedBox(height: 3),
                // Row 2: dusk time
                Row(
                  children: [
                    const Icon(Icons.nightlight_round,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
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

          const SizedBox(width: 8),

          // Moon emoji + illumination (with tooltip)
          Tooltip(
            message: _moonTooltip(f),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
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
                  '${(f.darkDuration.inMinutes / 60).toStringAsFixed(1)}h dark',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Night weather animation (with tooltip)
          Tooltip(
            message: _nightIconTooltip(f),
            child: NightWeatherIcon(forecast: f),
          ),

          const SizedBox(width: 8),

          // Score badge + chevron
          Column(
            children: [
              Tooltip(
                message: _scoreTooltip(f),
                child: ClearSkyScoreBadge(score: score),
              ),
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
}

// Small icon + label chip for collapsed header
class _WeatherChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _WeatherChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 2),
        Text(label,
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}

// ─── Expanded body ───────────────────────────────────────────────────────────

class _ExpandedBody extends StatefulWidget {
  final DayForecast forecast;
  final AppLocation location;

  const _ExpandedBody({required this.forecast, required this.location});

  @override
  State<_ExpandedBody> createState() => _ExpandedBodyState();
}

class _ExpandedBodyState extends State<_ExpandedBody> {
  int _selectedSlotIndex = 0;

  @override
  Widget build(BuildContext context) {
    final f = widget.forecast;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, indent: 14, endIndent: 14),
        // Dark window summary
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: _DarkWindowSummary(forecast: f),
        ),
        // Hourly grid + weather map side by side
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: HourlyConditionsGrid(
                    slots: f.darkHourSlots,
                    selectedIndex: _selectedSlotIndex,
                    onRowTap: (i) => setState(() => _selectedSlotIndex = i),
                  ),
                ),
                if (f.darkHourSlots.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 210,
                    child: _WeatherMapPanel(
                      location: widget.location,
                      slots: f.darkHourSlots,
                      selectedIndex: _selectedSlotIndex,
                    ),
                  ),
                ],
              ],
            ),
          ),
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

// ─── Weather map panel ───────────────────────────────────────────────────────

class _WeatherMapPanel extends StatelessWidget {
  final AppLocation location;
  final List<HourlySlot> slots;
  final int selectedIndex;

  const _WeatherMapPanel({
    required this.location,
    required this.slots,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(location.latitude, location.longitude);
    final slot = slots[selectedIndex.clamp(0, slots.length - 1)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 9.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.example.clearskies',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 24,
                    height: 24,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                      size: 20,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Weather overlay card at the bottom
          Positioned(
            bottom: 6,
            left: 6,
            right: 6,
            child: _MapOverlayCard(slot: slot),
          ),
        ],
      ),
    );
  }
}

class _MapOverlayCard extends StatelessWidget {
  final HourlySlot slot;
  const _MapOverlayCard({required this.slot});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(slot.time.toLocal());
    final windDir = slot.windDirectionDeg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(215),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🕐 $timeStr',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _OverlayChip('☁ ${slot.cloudCoverTotal}%'),
              _OverlayChip('🌡 ${slot.temperature.toStringAsFixed(0)}°C'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OverlayChip('💨 ${slot.windSpeedKnots.round()}kn'),
                  if (windDir != null) ...[
                    const SizedBox(width: 2),
                    Transform.rotate(
                      angle: windDir * math.pi / 180,
                      child: const Icon(
                        Icons.arrow_upward,
                        size: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              _OverlayChip('💧 ${slot.precipitationProbability}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  final String text;
  const _OverlayChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
    );
  }
}

// ─── Dark window summary ─────────────────────────────────────────────────────

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
    final avgSeeingStr =
        f.avgSeeing > 0 ? '${f.avgSeeing.toStringAsFixed(1)}/5' : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dark window time
        _InfoChip(
          icon: Icons.nightlight_outlined,
          label: 'Dark window',
          value: '$dusk – $dawn  ($h h ${m}m)',
        ),
        const SizedBox(height: 10),
        // Weather detail chips
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _DetailChip(
              icon: Icons.cloud_outlined,
              label: 'Cloud cover',
              value: '${f.bestCloudCover}%',
            ),
            _DetailChip(
              icon: Icons.thermostat,
              label: 'Temperature',
              value: '${f.avgTemperature.toStringAsFixed(1)}°C avg',
            ),
            _DetailChip(
              icon: Icons.air,
              label: 'Wind',
              value: '${f.avgWindKmh.round()} km/h avg',
            ),
            _DetailChip(
              icon: Icons.water_drop_outlined,
              label: 'Precipitation',
              value: '${f.maxPrecipPct}% max chance',
            ),
            _DetailChip(
              icon: Icons.opacity,
              label: 'Humidity',
              value: '${f.avgHumidity}% avg',
            ),
            _DetailChip(
              icon: Icons.remove_red_eye_outlined,
              label: 'Seeing',
              value: avgSeeingStr,
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(DateTime t) => DateFormat('HH:mm').format(t.toLocal());
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip(
      {required this.icon, required this.label, required this.value});

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

// Detailed chip used in expanded dark-window summary
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha(160),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 0.3)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
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
                      if (idx < 0 || idx >= slots.length) {
                        return const SizedBox();
                      }
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
              _MoonTime(
                  icon: Icons.arrow_upward, label: 'Moonrise', time: riseStr),
              const SizedBox(height: 2),
              _MoonTime(
                  icon: Icons.arrow_downward, label: 'Moonset', time: setStr),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) => DateFormat('h:mm a').format(t.toLocal());
}

class _MoonTime extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  const _MoonTime(
      {required this.icon, required this.label, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppColors.moonGold),
        const SizedBox(width: 3),
        Text(
          '$label $time',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
