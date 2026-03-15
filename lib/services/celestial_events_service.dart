import 'package:dio/dio.dart';
import '../models/celestial_event.dart';
import '../features/astronomy/astronomy_service.dart';

/// Aggregates celestial events from multiple sources:
///   - USNO Seasons API  (equinox / solstice / perihelion / aphelion)
///   - NOAA SWPC         (Kp geomagnetic / aurora forecast)
///   - Hardcoded calendar (meteor showers)
///   - AstronomyService  (planet visibility, new/full moon)
class CelestialEventsService {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'ClearSkiesApp/1.0 (stargazing forecast)'},
  ));

  final _astronomy = AstronomyService();

  // ─── Orbital events (USNO Seasons API) ─────────────────────────────────────

  Future<List<CelestialEvent>> getOrbitalEvents(int year) async {
    try {
      final resp = await _dio.get(
        'https://aa.usno.navy.mil/api/seasons',
        queryParameters: {'year': year},
      );
      final data = resp.data;
      final rawData = data['data'] as List<dynamic>?;
      if (rawData == null) return [];

      final events = <CelestialEvent>[];
      for (final item in rawData) {
        final phenom = item['phenom'] as String? ?? '';
        final month = item['month'] as int? ?? 1;
        final day = item['day'] as int? ?? 1;
        final timeStr = item['time'] as String? ?? '00:00';
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final date = DateTime.utc(year, month, day, hour, minute);

        final (name, desc) = _orbitalNameDesc(phenom);
        if (name.isEmpty) continue;
        events.add(CelestialEvent(
          type: CelestialEventType.orbital,
          name: name,
          date: date,
          description: desc,
        ));
      }
      return events;
    } catch (_) {
      return _hardcodedOrbitalFallback(year);
    }
  }

  (String, String) _orbitalNameDesc(String phenom) {
    switch (phenom.toLowerCase()) {
      case 'perihelion':
        return ('Perihelion', 'Earth at closest point to the Sun');
      case 'aphelion':
        return ('Aphelion', 'Earth at farthest point from the Sun');
      case 'spring equinox':
      case 'vernal equinox':
        return ('Spring Equinox', 'Day and night equal length; spring begins');
      case 'summer solstice':
        return ('Summer Solstice', 'Longest day of the year; summer begins');
      case 'autumnal equinox':
      case 'autumn equinox':
      case 'fall equinox':
        return ('Autumn Equinox', 'Day and night equal length; autumn begins');
      case 'winter solstice':
        return ('Winter Solstice', 'Shortest day of the year; winter begins');
      default:
        return ('', '');
    }
  }

  // Fallback hardcoded data for 2025-2028 if USNO is unreachable
  List<CelestialEvent> _hardcodedOrbitalFallback(int year) {
    final data = <int, List<(String, String, int, int)>>{
      2025: [
        ('Perihelion', 'Earth at closest point to the Sun', 1, 4),
        ('Spring Equinox', 'Day and night equal length; spring begins', 3, 20),
        ('Summer Solstice', 'Longest day of the year; summer begins', 6, 21),
        ('Aphelion', 'Earth at farthest point from the Sun', 7, 3),
        ('Autumn Equinox', 'Day and night equal length; autumn begins', 9, 22),
        ('Winter Solstice', 'Shortest day of the year; winter begins', 12, 21),
      ],
      2026: [
        ('Perihelion', 'Earth at closest point to the Sun', 1, 3),
        ('Spring Equinox', 'Day and night equal length; spring begins', 3, 20),
        ('Summer Solstice', 'Longest day of the year; summer begins', 6, 21),
        ('Aphelion', 'Earth at farthest point from the Sun', 7, 6),
        ('Autumn Equinox', 'Day and night equal length; autumn begins', 9, 23),
        ('Winter Solstice', 'Shortest day of the year; winter begins', 12, 21),
      ],
      2027: [
        ('Perihelion', 'Earth at closest point to the Sun', 1, 3),
        ('Spring Equinox', 'Day and night equal length; spring begins', 3, 20),
        ('Summer Solstice', 'Longest day of the year; summer begins', 6, 21),
        ('Aphelion', 'Earth at farthest point from the Sun', 7, 5),
        ('Autumn Equinox', 'Day and night equal length; autumn begins', 9, 23),
        ('Winter Solstice', 'Shortest day of the year; winter begins', 12, 22),
      ],
      2028: [
        ('Perihelion', 'Earth at closest point to the Sun', 1, 5),
        ('Spring Equinox', 'Day and night equal length; spring begins', 3, 20),
        ('Summer Solstice', 'Longest day of the year; summer begins', 6, 20),
        ('Aphelion', 'Earth at farthest point from the Sun', 7, 4),
        ('Autumn Equinox', 'Day and night equal length; autumn begins', 9, 22),
        ('Winter Solstice', 'Shortest day of the year; winter begins', 12, 21),
      ],
    };
    final yearData = data[year] ?? data[2026]!;
    return yearData.map((e) => CelestialEvent(
      type: CelestialEventType.orbital,
      name: e.$1,
      date: DateTime.utc(year, e.$3, e.$4, 12),
      description: e.$2,
    )).toList();
  }

  // ─── Aurora forecast (NOAA SWPC) ────────────────────────────────────────────

  Future<List<CelestialEvent>> getAuroraForecast(double lat) async {
    // Minimum Kp needed for aurora to be visible at this latitude
    final minKp = _minKpForLatitude(lat);
    if (minKp >= 9) return []; // too far south

    try {
      final resp = await _dio.get(
        'https://services.swpc.noaa.gov/products/noaa-planetary-k-index-forecast.json',
      );
      final rows = resp.data as List<dynamic>;
      // First row is the header
      final events = <CelestialEvent>[];
      DateTime? lastAuroraDate;

      for (final row in rows.skip(1)) {
        final timeTag = row[0] as String;
        final kpRaw = row[1];
        final kp = kpRaw is num
            ? kpRaw.toDouble()
            : double.tryParse(kpRaw.toString()) ?? 0.0;
        final observed = (row[2] as String?) ?? '';

        // Only use predicted/estimated future data
        if (observed == 'observed') continue;
        if (kp < minKp) continue;

        final date = _parseNoaaTime(timeTag);
        if (date == null) continue;
        final dateOnly = DateTime.utc(date.year, date.month, date.day);

        // One event per day maximum
        if (lastAuroraDate != null &&
            lastAuroraDate.year == dateOnly.year &&
            lastAuroraDate.month == dateOnly.month &&
            lastAuroraDate.day == dateOnly.day) {
          continue;
        }

        lastAuroraDate = dateOnly;
        events.add(CelestialEvent(
          type: CelestialEventType.aurora,
          name: 'Aurora Possible',
          date: dateOnly,
          description: 'Kp ${kp.toStringAsFixed(1)} — geomagnetic activity may produce aurora overhead',
        ));
      }
      return events;
    } catch (_) {
      return [];
    }
  }

  int _minKpForLatitude(double lat) {
    if (lat >= 65) return 0;
    if (lat >= 60) return 2;
    if (lat >= 55) return 4;
    if (lat >= 50) return 6;
    if (lat >= 45) return 7;
    return 9;
  }

  DateTime? _parseNoaaTime(String s) {
    // Format: "2026-03-14 06:00:00"
    try {
      return DateTime.parse('${s.replaceFirst(' ', 'T')}Z');
    } catch (_) {
      return null;
    }
  }

  // ─── Meteor showers (hardcoded annual calendar) ──────────────────────────────

  static const _showers = [
    (name: 'Quadrantids',     month: 1,  day: 4,  zhr: 120),
    (name: 'Lyrids',          month: 4,  day: 22, zhr: 18),
    (name: 'Eta Aquariids',   month: 5,  day: 6,  zhr: 50),
    (name: 'Delta Aquariids', month: 7,  day: 30, zhr: 20),
    (name: 'Perseids',        month: 8,  day: 12, zhr: 100),
    (name: 'Draconids',       month: 10, day: 8,  zhr: 20),
    (name: 'Orionids',        month: 10, day: 21, zhr: 20),
    (name: 'Leonids',         month: 11, day: 17, zhr: 15),
    (name: 'Geminids',        month: 12, day: 14, zhr: 120),
    (name: 'Ursids',          month: 12, day: 22, zhr: 10),
  ];

  List<CelestialEvent> getMeteorShowers(DateTime from, DateTime to) {
    final events = <CelestialEvent>[];
    for (final shower in _showers) {
      // Check this year and next (handles year boundary)
      for (final year in [from.year, from.year + 1]) {
        final peak = DateTime.utc(year, shower.month, shower.day);
        // Include ±3 days around peak
        final windowStart = peak.subtract(const Duration(days: 3));
        final windowEnd = peak.add(const Duration(days: 3));
        if (windowEnd.isBefore(from) || windowStart.isAfter(to)) continue;
        final intensity = shower.zhr >= 100
            ? 'Major (up to ${shower.zhr}/hr)'
            : shower.zhr >= 30
                ? 'Moderate (~${shower.zhr}/hr)'
                : 'Minor (~${shower.zhr}/hr)';
        events.add(CelestialEvent(
          type: CelestialEventType.meteorShower,
          name: '${shower.name} Meteor Shower',
          date: peak,
          description: '$intensity — peak night',
        ));
      }
    }
    return events;
  }

  // ─── Planet visibility ───────────────────────────────────────────────────────

  static const _planets = ['Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn'];

  List<CelestialEvent> getPlanetEvents(
    double lat,
    double lon,
    DateTime from,
    DateTime to,
  ) {
    final events = <CelestialEvent>[];
    var d = from;
    while (!d.isAfter(to)) {
      for (final planet in _planets) {
        final visible = _astronomy.isPlanetVisibleOnNight(
          planet: planet,
          lat: lat,
          lon: lon,
          date: d,
        );
        if (visible) {
          events.add(CelestialEvent(
            type: CelestialEventType.planet,
            name: '$planet Visible',
            date: DateTime.utc(d.year, d.month, d.day),
            description: '$planet rises above 10° during tonight\'s dark window',
          ));
        }
      }
      d = d.add(const Duration(days: 1));
    }
    return events;
  }

  // ─── Moon phase events ───────────────────────────────────────────────────────

  List<CelestialEvent> getMoonEvents(DateTime from, DateTime to) {
    final days = to.difference(from).inDays + 1;
    final phaseEvents = _astronomy.findMoonPhaseEvents(from: from, days: days);
    return phaseEvents
        .where((e) => !e.$1.isAfter(to))
        .map((e) => CelestialEvent(
              type: CelestialEventType.moon,
              name: e.$2,
              date: e.$1,
              description: e.$2 == 'New Moon'
                  ? 'Darkest nights — best for deep-sky observing'
                  : 'Bright moon may reduce sky darkness',
            ))
        .toList();
  }

  // ─── Aggregate ───────────────────────────────────────────────────────────────

  Future<List<CelestialEvent>> getAll({
    required double lat,
    required double lon,
  }) async {
    final now = DateTime.now().toUtc();
    final windowEnd = now.add(const Duration(days: 42)); // 6 weeks

    // Run API calls concurrently
    final results = await Future.wait([
      getOrbitalEvents(now.year),
      getOrbitalEvents(now.year + 1), // catch events early next year
      getAuroraForecast(lat),
    ]);

    final orbital = [...results[0], ...results[1]];
    final aurora = results[2];

    final showers = getMeteorShowers(now, windowEnd);
    final planets = getPlanetEvents(lat, lon, now, windowEnd);
    final moons = getMoonEvents(now, windowEnd);

    // Combine and filter to the 30-day window
    final all = <CelestialEvent>[
      ...orbital.where((e) => !e.date.isBefore(now) && !e.date.isAfter(windowEnd)),
      ...aurora,
      ...showers,
      ...planets,
      ...moons,
    ];

    all.sort((a, b) => a.date.compareTo(b.date));
    return all;
  }
}
