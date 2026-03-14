import '../../models/hourly_slot.dart';
import 'weather_data_source.dart';

/// Met Office DataPoint stub — enabled when an API key is configured in Settings.
/// Implements the same [WeatherDataSource] interface as [OpenMeteoSource].
class MetOfficeSource implements WeatherDataSource {
  final String apiKey;

  const MetOfficeSource({required this.apiKey});

  @override
  Future<List<HourlySlot>> fetchHourly({
    required double lat,
    required double lon,
    required DateTime from,
    required int days,
  }) async {
    // TODO: Implement Met Office DataPoint API integration.
    //
    // Endpoint: https://api-metoffice.apiconnect.ibmcloud.com/metoffice/production/v0/forecasts/point/hourly
    // Headers: X-IBM-Client-Id: apiKey, X-IBM-Client-Secret: apiKey
    // Params: latitude, longitude, includeLocationName=true
    //
    // Response fields to map:
    //   - screenRelativeHumidity → humidity
    //   - precipitationRate → precipitationProbability
    //   - totalSnowAmount / totalPrecipAmount
    //   - windSpeed10m → windSpeedKnots (convert m/s × 1.944)
    //   - totalCloudCover → cloudCoverTotal (oktas × 12.5 to get %)
    //   - screenDewPointTemperature → dewPoint
    //   - screenTemperature → temperature
    //   - visibility → derive transparency
    //   - significantWeatherCode → cloud type inference
    //
    // The Met Office provides up to 2 days hourly, then 3-hourly to day 7.
    // For days 8–14, fall back to Open-Meteo.
    throw UnimplementedError(
        'Met Office integration pending API key configuration.');
  }
}
