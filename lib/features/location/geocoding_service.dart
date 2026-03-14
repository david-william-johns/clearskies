import 'package:dio/dio.dart';
import '../../models/location.dart';

class GeocodingService {
  final Dio _dio;

  GeocodingService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                // Nominatim requires a User-Agent
                'User-Agent': 'ClearSkiesApp/1.0 (stargazing forecast)',
              },
            ));

  static final _postcodeRegex =
      RegExp(r'^[A-Z]{1,2}\d[A-Z\d]?\s*\d[A-Z]{2}$', caseSensitive: false);

  /// Resolves a postcode or city/town name into an [AppLocation].
  /// Throws [GeocodingException] if the query cannot be resolved.
  Future<AppLocation> resolve(String query) async {
    final trimmed = query.trim();
    if (_postcodeRegex.hasMatch(trimmed)) {
      return _resolvePostcode(trimmed.replaceAll(' ', '').toUpperCase());
    }
    return _resolveCity(trimmed);
  }

  Future<AppLocation> _resolvePostcode(String postcode) async {
    try {
      final response = await _dio
          .get('https://api.postcodes.io/postcodes/$postcode');
      if (response.statusCode == 200) {
        final result = response.data['result'] as Map<String, dynamic>;
        return AppLocation(
          latitude: (result['latitude'] as num).toDouble(),
          longitude: (result['longitude'] as num).toDouble(),
          displayName:
              '${result['admin_district'] ?? result['parish'] ?? postcode}, UK',
          postcode: postcode,
        );
      }
      throw GeocodingException('Postcode not found: $postcode');
    } on DioException catch (e) {
      throw GeocodingException('Network error: ${e.message}');
    }
  }

  Future<AppLocation> _resolveCity(String city) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': city,
          'format': 'json',
          'limit': 1,
          'addressdetails': 1,
        },
      );
      final results = response.data as List<dynamic>;
      if (results.isEmpty) {
        throw GeocodingException('Location not found: $city');
      }
      final r = results.first as Map<String, dynamic>;
      return AppLocation(
        latitude: double.parse(r['lat'] as String),
        longitude: double.parse(r['lon'] as String),
        displayName: _extractDisplayName(r),
      );
    } on DioException catch (e) {
      throw GeocodingException('Network error: ${e.message}');
    }
  }

  String _extractDisplayName(Map<String, dynamic> r) {
    final addr = r['address'] as Map<String, dynamic>?;
    if (addr != null) {
      final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'];
      final country = addr['country'];
      if (city != null) return country != null ? '$city, $country' : city;
    }
    // Fallback: first two parts of display_name
    final parts = (r['display_name'] as String).split(',');
    return parts.take(2).map((s) => s.trim()).join(', ');
  }
}

class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);

  @override
  String toString() => 'GeocodingException: $message';
}
