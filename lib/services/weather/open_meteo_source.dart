import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../../models/hourly_slot.dart';
import 'weather_data_source.dart';

class OpenMeteoSource implements WeatherDataSource {
  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  final Dio _dio;

  OpenMeteoSource({Dio? dio}) : _dio = _buildDio(dio);

  static Dio _buildDio(Dio? base) {
    final options = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.forceCache,
      maxStale: const Duration(hours: 1),
    );
    final d = base ?? Dio();
    d.interceptors.add(DioCacheInterceptor(options: options));
    return d;
  }

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
        'latitude': lat,
        'longitude': lon,
        'hourly': [
          'cloudcover',
          'cloudcover_low',
          'cloudcover_mid',
          'cloudcover_high',
          'relativehumidity_2m',
          'windspeed_10m',
          'precipitation_probability',
          'dewpoint_2m',
          'temperature_2m',
        ].join(','),
        'forecast_days': days,
        'wind_speed_unit': 'kn',
        'timezone': 'Europe/London',
      },
    );

    final hourly = response.data['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final cc = (hourly['cloudcover'] as List).cast<num>();
    final ccLow = (hourly['cloudcover_low'] as List).cast<num>();
    final ccMid = (hourly['cloudcover_mid'] as List).cast<num>();
    final ccHigh = (hourly['cloudcover_high'] as List).cast<num>();
    final rh = (hourly['relativehumidity_2m'] as List).cast<num>();
    final ws = (hourly['windspeed_10m'] as List).cast<num>();
    final pp = (hourly['precipitation_probability'] as List?)?.cast<num>() ??
        List.filled(times.length, 0);
    final dp = (hourly['dewpoint_2m'] as List).cast<num>();
    final temp = (hourly['temperature_2m'] as List).cast<num>();

    final slots = <HourlySlot>[];
    for (int i = 0; i < times.length; i++) {
      final t = DateTime.parse('${times[i]}:00Z').toUtc();
      if (t.isBefore(from.subtract(const Duration(hours: 1)))) continue;
      slots.add(HourlySlot(
        time: t,
        cloudCoverTotal: (cc[i]).round(),
        cloudCoverLow: (ccLow[i]).round(),
        cloudCoverMid: (ccMid[i]).round(),
        cloudCoverHigh: (ccHigh[i]).round(),
        humidity: (rh[i]).round(),
        windSpeedKnots: (ws[i]).toDouble(),
        precipitationProbability: (pp[i]).round(),
        dewPoint: (dp[i]).toDouble(),
        temperature: (temp[i]).toDouble(),
        // Defaults — will be merged from SevenTimer
        seeing: 3,
        transparency: 3,
        moonAltitudeDeg: 0,
      ));
    }
    return slots;
  }
}
