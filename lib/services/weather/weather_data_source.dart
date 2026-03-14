import '../../models/hourly_slot.dart';

/// Abstract interface for weather data providers.
/// Implement this to add Met Office or any other provider.
abstract class WeatherDataSource {
  /// Fetch hourly weather data for [days] days ahead starting from [from].
  /// Returns a flat list of [HourlySlot] covering all requested days.
  Future<List<HourlySlot>> fetchHourly({
    required double lat,
    required double lon,
    required DateTime from,
    required int days,
  });
}
