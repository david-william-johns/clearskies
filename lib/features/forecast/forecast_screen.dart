import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/location.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mini_calendar.dart';
import '../../widgets/celestial_events_column.dart';
import '../../widgets/history_panel.dart';
import '../location/location_search_screen.dart';
import 'forecast_providers.dart';
import 'day_forecast_tile.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(locationProvider);

    return locationAsync.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(message: e.toString()),
      data: (location) {
        if (location == null) {
          return const LocationSearchScreen(isFirstRun: true);
        }
        return _ForecastBody(location: location);
      },
    );
  }
}

class _ForecastBody extends ConsumerWidget {
  final AppLocation location;
  const _ForecastBody({required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider(location));
    final celestialAsync = ref.watch(celestialEventsProvider(location));
    final celestialEvents = celestialAsync.valueOrNull ?? [];

    final screenWidth = MediaQuery.of(context).size.width;
    final leftWidth = screenWidth < 600 ? 145.0 : 185.0;
    final showHistory = screenWidth >= 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.background.withAlpha(215),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.stars, color: AppColors.primary, size: 16),
                SizedBox(width: 6),
                Text(
                  'ClearSkies',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Text(
              location.displayName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(forecastProvider(location)),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textSecondary),
            tooltip: 'Change location',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const LocationSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            tooltip: 'Settings',
            onPressed: null,
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left panel: 2-month calendar + celestial events ──────────────
          SizedBox(
            width: leftWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 14, 4, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiniCalendar(allEvents: celestialEvents),
                  CelestialEventsColumn(events: celestialEvents),
                ],
              ),
            ),
          ),

          // ── Centre panel: forecast tiles ─────────────────────────────────
          Expanded(
            child: forecastAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary)),
                    SizedBox(height: 16),
                    Text('Fetching sky conditions…',
                        style:
                            TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              error: (e, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off,
                          color: AppColors.textSecondary, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not load forecast',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.toString(),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () =>
                            ref.invalidate(forecastProvider(location)),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary, width: 1)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (forecasts) {
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(forecastProvider(location)),
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface.withAlpha(200),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _LegendBar(),
                      const SizedBox(height: 4),
                      ...forecasts.asMap().entries.map((e) {
                        return DayForecastTile(
                          key: ValueKey(e.value.date),
                          forecast: e.value,
                          location: location,
                          initiallyExpanded: false,
                        )
                            .animate(delay: (e.key * 40).ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.05, end: 0, duration: 300.ms);
                      }),
                      const SizedBox(height: 20),
                      const _Footer(),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Right panel: This Day in History ─────────────────────────────
          if (showHistory)
            SizedBox(
              width: 220,
              child: SingleChildScrollView(
                child: const HistoryPanel(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          const Text(
            'SCORE  ',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 9, letterSpacing: 0.6),
          ),
          _Legend(color: AppColors.scoreExcellent, label: '≥80 Excellent'),
          _Legend(color: AppColors.scoreGood, label: '65 Good'),
          _Legend(color: AppColors.scoreFair, label: '50 Fair'),
          _Legend(color: AppColors.scoreAmber, label: '35 Poor'),
          _Legend(color: AppColors.scorePoor, label: '<35 Cloudy'),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        'Weather: Open-Meteo · Seeing: 7timer.info · Astronomy: computed\n'
        'Scores weighted: cloud 40% · seeing 25% · transparency 20% · moon 10% · humidity 3% · wind 2%',
        style:
            TextStyle(color: AppColors.textMuted, fontSize: 9, height: 1.6),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Edge-state scaffolds ─────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary)),
      ),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  final String message;
  const _ErrorScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(message,
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
