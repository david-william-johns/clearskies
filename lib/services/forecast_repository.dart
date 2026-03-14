import '../features/astronomy/astronomy_service.dart';
import '../models/day_forecast.dart';
import '../models/hourly_slot.dart';
import 'weather/open_meteo_source.dart';
import 'weather/seven_timer_source.dart';

class ForecastRepository {
  final OpenMeteoSource _openMeteo;
  final SevenTimerSource _sevenTimer;
  final AstronomyService _astronomy;

  ForecastRepository({
    OpenMeteoSource? openMeteo,
    SevenTimerSource? sevenTimer,
    AstronomyService? astronomy,
  })  : _openMeteo = openMeteo ?? OpenMeteoSource(),
        _sevenTimer = sevenTimer ?? SevenTimerSource(),
        _astronomy = astronomy ?? AstronomyService();

  /// Fetches and merges forecasts for 14 days, returning one [DayForecast] per day.
  Future<List<DayForecast>> getForecast({
    required double lat,
    required double lon,
    int days = 14,
  }) async {
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);

    // Fetch both sources in parallel
    final results = await Future.wait([
      _openMeteo.fetchHourly(lat: lat, lon: lon, from: today, days: days),
      _sevenTimer
          .fetchAstroData(lat: lat, lon: lon)
          .catchError((_) => <DateTime, ({int seeing, int transparency})>{}),
    ]);

    final meteoSlots = results[0] as List<HourlySlot>;
    final astroData =
        results[1] as Map<DateTime, ({int seeing, int transparency})>;

    // Build a lookup by hour for astro data (3-hourly, so match nearest)
    final astroLookup = <DateTime, ({int seeing, int transparency})>{};
    for (final e in astroData.entries) {
      // Round to nearest 3-hour block
      final h = e.key;
      for (int offset = -1; offset <= 2; offset++) {
        astroLookup[h.add(Duration(hours: offset))] = e.value;
      }
    }

    // Enrich meteo slots with seeing/transparency and moon altitude
    final enrichedSlots = meteoSlots.map((s) {
      final astro = astroLookup[s.time];
      final moonAlt = _astronomy.moonAltitude(
        lat: lat,
        lon: lon,
        time: s.time,
      );
      return HourlySlot(
        time: s.time,
        cloudCoverTotal: s.cloudCoverTotal,
        cloudCoverLow: s.cloudCoverLow,
        cloudCoverMid: s.cloudCoverMid,
        cloudCoverHigh: s.cloudCoverHigh,
        humidity: s.humidity,
        windSpeedKnots: s.windSpeedKnots,
        precipitationProbability: s.precipitationProbability,
        dewPoint: s.dewPoint,
        temperature: s.temperature,
        seeing: astro?.seeing ?? 3,
        transparency: astro?.transparency ?? 3,
        moonAltitudeDeg: moonAlt,
      );
    }).toList();

    // Group by UTC date and build DayForecast
    final dayForecasts = <DayForecast>[];
    for (int d = 0; d < days; d++) {
      final date = today.add(Duration(days: d));
      // Get twilight for this night (evening of `date`, morning of `date+1`)
      final (dusk, dawn) = _astronomy.getAstronomicalTwilight(
        lat: lat,
        lon: lon,
        forDate: date,
      );

      // Fallback twilight if sun is always above/below horizon
      final effectiveDusk = dusk ?? date.add(const Duration(hours: 21));
      final effectiveDawn =
          dawn ?? date.add(const Duration(hours: 1, days: 1));

      // Filter slots to dark hours for this night
      final darkSlots = enrichedSlots.where((s) {
        return !s.time.isBefore(effectiveDusk) &&
            s.time.isBefore(effectiveDawn);
      }).toList();

      final moonPhase = _astronomy.moonPhase(date);
      final (moonRise, moonSet) = _astronomy.getMoonRiseSet(
        lat: lat,
        lon: lon,
        forDate: date,
      );

      dayForecasts.add(DayForecast(
        date: date,
        astronomicalDusk: effectiveDusk,
        astronomicalDawn: effectiveDawn,
        moonPhase: moonPhase,
        moonRise: moonRise,
        moonSet: moonSet,
        darkHourSlots: darkSlots,
      ));
    }

    return dayForecasts;
  }
}
