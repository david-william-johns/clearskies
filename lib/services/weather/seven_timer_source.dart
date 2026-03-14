import 'package:dio/dio.dart';
import '../../models/hourly_slot.dart';
import 'weather_data_source.dart';

/// 7timer.info ASTRO product — provides seeing & transparency on a 3-hourly basis.
/// Used to supplement Open-Meteo data.
class SevenTimerSource implements WeatherDataSource {
  static const _baseUrl = 'http://www.7timer.info/bin/api.pl';

  final Dio _dio;

  SevenTimerSource({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<List<HourlySlot>> fetchHourly({
    required double lat,
    required double lon,
    required DateTime from,
    required int days,
  }) async {
    final response = await _dio.get(
      _baseUrl,
      queryParameters: {
        'lon': lon.toStringAsFixed(4),
        'lat': lat.toStringAsFixed(4),
        'product': 'astro',
        'output': 'json',
      },
    );

    final init = response.data['init'] as String;
    // init format: "YYYYMMDDHH"
    final initTime = DateTime.utc(
      int.parse(init.substring(0, 4)),
      int.parse(init.substring(4, 6)),
      int.parse(init.substring(6, 8)),
      int.parse(init.substring(8, 10)),
    );

    final series = (response.data['dataseries'] as List).cast<Map<String, dynamic>>();
    final slots = <HourlySlot>[];

    for (final entry in series) {
      final timepoint = entry['timepoint'] as int;
      final slotTime = initTime.add(Duration(hours: timepoint));

      // 7timer seeing: 1=<0.5", 2=0.5-0.75", 3=0.75-1", 4=1-1.5", 5=1.5-2", 6=2-2.5", 7>2.5"
      // Map to our 1–5 scale (5=best, 1=worst): invert and cap
      final rawSeeing = (entry['seeing'] as int? ?? 4).clamp(1, 7);
      final seeing = (8 - rawSeeing).clamp(1, 5); // invert: 7→1, 1→5 (but cap at 5)
      final seeingMapped = seeing > 5 ? 5 : seeing;

      // transparency: 1=<0.3mag, 2=0.3-0.4, 3=0.4-0.5, 4=0.5-0.6, 5=0.6-0.7, 6=0.7-0.85, 7=0.85+
      final rawTrans = (entry['transparency'] as int? ?? 4).clamp(1, 7);
      final trans = (8 - rawTrans).clamp(1, 5);
      final transMapped = trans > 5 ? 5 : trans;

      // 7timer cloud cover: 1=0-6%, 2=6-19%, 3=19-31%, 4=31-44%, 5=44-56%,
      //                     6=56-69%, 7=69-81%, 8=81-94%, 9=94-100%
      final rawCloud = (entry['cloudcover'] as int? ?? 5).clamp(1, 9);
      final cloudPct = ((rawCloud - 1) / 8 * 100).round();

      slots.add(HourlySlot(
        time: slotTime,
        cloudCoverTotal: cloudPct,
        cloudCoverLow: cloudPct ~/ 2,
        cloudCoverMid: cloudPct ~/ 3,
        cloudCoverHigh: cloudPct ~/ 4,
        humidity: 60,
        windSpeedKnots: 5,
        precipitationProbability: 0,
        dewPoint: 5,
        temperature: 10,
        seeing: seeingMapped,
        transparency: transMapped,
        moonAltitudeDeg: 0,
      ));
    }
    return slots;
  }

  /// Returns only the seeing/transparency map keyed by UTC hour.
  Future<Map<DateTime, ({int seeing, int transparency})>> fetchAstroData({
    required double lat,
    required double lon,
  }) async {
    try {
      final slots = await fetchHourly(
          lat: lat, lon: lon, from: DateTime.now().toUtc(), days: 8);
      return {
        for (final s in slots)
          s.time: (seeing: s.seeing, transparency: s.transparency),
      };
    } catch (_) {
      return {};
    }
  }
}
