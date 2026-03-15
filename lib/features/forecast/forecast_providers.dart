import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/celestial_event.dart';
import '../../models/day_forecast.dart';
import '../../models/location.dart';
import '../../services/celestial_events_service.dart';
import '../../services/forecast_repository.dart';

// ─── Location provider ───────────────────────────────────────────────────────

class LocationNotifier extends AsyncNotifier<AppLocation?> {
  static const _prefKey = 'last_location';

  @override
  Future<AppLocation?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefKey);
    if (json == null) return null;
    try {
      return AppLocation.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLocation(AppLocation loc) async {
    state = AsyncData(loc);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(loc.toJson()));
  }
}

final locationProvider =
    AsyncNotifierProvider<LocationNotifier, AppLocation?>(LocationNotifier.new);

// ─── Forecast provider ───────────────────────────────────────────────────────

final forecastRepositoryProvider = Provider<ForecastRepository>(
  (_) => ForecastRepository(),
);

final forecastProvider =
    FutureProvider.family<List<DayForecast>, AppLocation>((ref, loc) async {
  final repo = ref.watch(forecastRepositoryProvider);
  return repo.getForecast(lat: loc.latitude, lon: loc.longitude);
});

// ─── OWM API key provider ─────────────────────────────────────────────────────

final owmApiKeyProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('owm_api_key') ?? '';
});

// ─── Celestial events provider ───────────────────────────────────────────────

final celestialEventsProvider =
    FutureProvider.family<List<CelestialEvent>, AppLocation>((ref, loc) async {
  final service = CelestialEventsService();
  return service.getAll(lat: loc.latitude, lon: loc.longitude);
});
