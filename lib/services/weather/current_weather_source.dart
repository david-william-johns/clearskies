import 'package:dio/dio.dart';
import '../../models/current_weather.dart';

class CurrentWeatherSource {
  final Dio _dio = Dio();

  Future<CurrentWeather> fetchCurrent({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,cloud_cover,wind_speed_10m,'
            'relative_humidity_2m,precipitation_probability',
        'wind_speed_unit': 'kmh',
      },
    );

    final data = response.data!;
    final current = data['current'] as Map<String, dynamic>;

    return CurrentWeather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      cloudCover: (current['cloud_cover'] as num).toInt(),
      windSpeedKmh: (current['wind_speed_10m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      precipitationProbability:
          (current['precipitation_probability'] as num? ?? 0).toInt(),
    );
  }
}
