import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../models/location.dart';
import '../../theme/app_theme.dart';
import 'forecast_providers.dart';

class CurrentConditionsPanel extends ConsumerWidget {
  final AppLocation location;

  const CurrentConditionsPanel({super.key, required this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentWeatherProvider(location));
    final owmKey = ref.watch(owmApiKeyProvider).valueOrNull ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(190),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    size: 10, color: AppColors.scoreExcellent),
                const SizedBox(width: 6),
                const Text(
                  'CURRENT CONDITIONS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  location.displayName,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 9),
                ),
              ],
            ),
          ),

          // ── Condition chips ──────────────────────────────────────────────
          currentAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Text(
                'Current conditions unavailable',
                style:
                    TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ),
            data: (cw) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  _CondChip(
                      icon: Icons.thermostat,
                      label:
                          '${cw.temperature.toStringAsFixed(1)}°C'),
                  _CondChip(
                      icon: Icons.cloud_outlined,
                      label: '${cw.cloudCover}% cloud'),
                  _CondChip(
                      icon: Icons.air,
                      label:
                          '${cw.windSpeedKmh.round()} km/h'),
                  _CondChip(
                      icon: Icons.opacity,
                      label: '${cw.humidity}% humidity'),
                  _CondChip(
                      icon: Icons.water_drop_outlined,
                      label: '${cw.precipitationProbability}% precip'),
                ],
              ),
            ),
          ),

          // ── Interactive satellite map ────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 260,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter:
                      LatLng(location.latitude, location.longitude),
                  initialZoom: 8.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.example.clearskies',
                  ),
                  if (owmKey.isNotEmpty)
                    Opacity(
                      opacity: 0.80,
                      child: TileLayer(
                        urlTemplate:
                            'https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=$owmKey',
                        userAgentPackageName: 'com.example.clearskies',
                      ),
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                            location.latitude, location.longitude),
                        width: 28,
                        height: 28,
                        child: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 22,
                          shadows: [
                            Shadow(
                                color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CondChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CondChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
