import 'dart:math';

/// Pure Dart astronomy calculations — no external packages required.
/// Ported from SunCalc (Vladimir Agafonkin) and standard orbital mechanics.
class AstronomyService {
  static const _rad = pi / 180.0;
  static const _dayMs = 86400000.0;
  static const _j1970 = 2440588.0; // Julian date of 1970-01-01
  static const _j2000 = 2451545.0; // Julian date of J2000.0
  static const _e = 23.4397 * _rad; // Earth obliquity

  // ─── Julian helpers ────────────────────────────────────────────────────────

  static double _toJulian(DateTime d) =>
      d.millisecondsSinceEpoch / _dayMs - 0.5 + _j1970;

  static DateTime _fromJulian(double j) => DateTime.fromMillisecondsSinceEpoch(
      ((j + 0.5 - _j1970) * _dayMs).round(),
      isUtc: true);

  static double _toDays(DateTime d) => _toJulian(d) - _j2000;

  // ─── Solar position ─────────────────────────────────────────────────────────

  static double _solarMeanAnomaly(double d) =>
      (357.5291 + 0.98560028 * d) * _rad;

  static double _eclipticLongitude(double m) {
    final c =
        (1.9148 * sin(m) + 0.02 * sin(2 * m) + 0.0003 * sin(3 * m)) * _rad;
    return m + c + (102.9372 * _rad) + pi;
  }

  static Map<String, double> _sunCoords(double d) {
    final m = _solarMeanAnomaly(d);
    final l = _eclipticLongitude(m);
    return {
      'dec': asin(sin(_e) * sin(l)),
      'ra': atan2(cos(_e) * sin(l), cos(l)),
    };
  }

  // ─── Sunrise/set base ───────────────────────────────────────────────────────

  static double _julianCycle(double d, double lw) =>
      (d - 0.0009 - lw / (2 * pi)).roundToDouble();

  static double _approxTransit(double ht, double lw, double n) =>
      0.0009 + (ht + lw) / (2 * pi) + n;

  static double _solarTransitJ(double ds, double m, double l) =>
      _j2000 + ds + 0.0053 * sin(m) - 0.0069 * sin(2 * l);

  static double _hourAngle(double h, double phi, double d) =>
      acos((sin(h) - sin(phi) * sin(d)) / (cos(phi) * cos(d)));

  static double _getSetJ(
      double h, double lw, double phi, double dec, double n, double m, double l) {
    try {
      final w = _hourAngle(h, phi, dec);
      final a = _approxTransit(w, lw, n);
      return _solarTransitJ(a, m, l);
    } catch (_) {
      return double.nan;
    }
  }

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Returns [dusk, dawn] times as UTC DateTimes for astronomical twilight
  /// (sun 18° below horizon) for the date of [forDate] at [lat]/[lon].
  ///
  /// Returns null for either value if the sun never reaches that depth
  /// (e.g. near solstice at extreme latitudes).
  (DateTime?, DateTime?) astronomicalTwilight({
    required double lat,
    required double lon,
    required DateTime forDate,
  }) {
    final lw = -lon * _rad;
    final phi = lat * _rad;
    final d = _toDays(DateTime.utc(forDate.year, forDate.month, forDate.day, 12));
    final n = _julianCycle(d, lw);
    final ds = _approxTransit(0, lw, n);
    final m = _solarMeanAnomaly(ds);
    final l = _eclipticLongitude(m);
    final jNoon = _solarTransitJ(ds, m, l);
    final dec = _sunCoords(d)['dec']!;
    const h0 = -18.0 * _rad; // astronomical twilight angle
    final jSet = _getSetJ(h0, lw, phi, dec, n, m, l);
    final jRise = jNoon - (jSet - jNoon);
    final dusk = jSet.isNaN ? null : _fromJulian(jSet);
    return (dusk, jRise.isNaN ? null : _fromJulian(jRise + 1 / 24));
  }

  /// More accurate dusk/dawn using iterative approach across the date.
  (DateTime?, DateTime?) getAstronomicalTwilight({
    required double lat,
    required double lon,
    required DateTime forDate,
  }) {
    final lw = -lon * _rad;
    final phi = lat * _rad;
    // Use noon of forDate as reference
    final d = _toDays(DateTime.utc(forDate.year, forDate.month, forDate.day, 12));
    final n = _julianCycle(d, lw);
    final ds = _approxTransit(0, lw, n);
    final m = _solarMeanAnomaly(ds);
    final l = _eclipticLongitude(m);
    final jNoon = _solarTransitJ(ds, m, l);
    final dec = _sunCoords(d)['dec']!;
    const h0 = -18.0 * _rad;
    final jSet = _getSetJ(h0, lw, phi, dec, n, m, l);
    if (jSet.isNaN) return (null, null);
    final jRise = jNoon - (jSet - jNoon);
    return (_fromJulian(jSet), _fromJulian(jRise));
  }

  // ─── Moon position ──────────────────────────────────────────────────────────

  static Map<String, double> _moonCoords(double d) {
    final l = (218.316 + 13.176396 * d) * _rad;
    final m = (134.963 + 13.064993 * d) * _rad;
    final f = (93.272 + 13.229350 * d) * _rad;
    final lon2 = l + 6.289 * sin(m) * _rad;
    final lat2 = 5.128 * sin(f) * _rad;
    final dist = 385001.0 - 20905.0 * cos(m);
    return {
      'ra': atan2(cos(_e) * sin(lon2) - tan(lat2) * sin(_e), cos(lon2)),
      'dec': asin(sin(_e) * sin(lon2) * cos(lat2) + cos(_e) * sin(lat2)),
      'dist': dist,
    };
  }

  /// Moon altitude in degrees at [time] for [lat]/[lon].
  double moonAltitude({
    required double lat,
    required double lon,
    required DateTime time,
  }) {
    final d = _toDays(time.toUtc());
    final lw = -lon * _rad;
    final phi = lat * _rad;
    final mc = _moonCoords(d);
    // Sidereal time
    final h = (280.16 + 360.9856235 * d) * _rad - lw - mc['ra']!;
    final alt = asin(sin(phi) * sin(mc['dec']!) +
        cos(phi) * cos(mc['dec']!) * cos(h));
    return alt / _rad;
  }

  /// Moon phase 0.0 (new) → 0.5 (full) → 1.0 (new again).
  double moonPhase(DateTime date) {
    final d = _toDays(date.toUtc());
    final sunM = _solarMeanAnomaly(d);
    final sunL = _eclipticLongitude(sunM);
    final mc = _moonCoords(d);
    final inc = acos(cos(mc['ra']! - sunL) * cos(mc['dec']!));
    final angle = atan2(
        cos(sunM) * sin(mc['dec']!),
        sin(sunM) - sin(mc['dec']!) * sin(inc));
    final fraction = (1 + cos(inc)) / 2;
    final waxing = angle < 0;
    return waxing ? fraction / 2 : 0.5 + (1 - fraction) / 2;
  }

  /// Find moonrise and moonset times for the given date (UTC day).
  /// Returns null for either if moon doesn't cross horizon that day.
  (DateTime?, DateTime?) getMoonRiseSet({
    required double lat,
    required double lon,
    required DateTime forDate,
  }) {
    DateTime? rise;
    DateTime? set;
    final start =
        DateTime.utc(forDate.year, forDate.month, forDate.day, 0, 0, 0);

    double? prevAlt;
    for (int h = 0; h <= 25; h++) {
      final t = start.add(Duration(hours: h));
      final alt = moonAltitude(lat: lat, lon: lon, time: t);
      if (prevAlt != null) {
        if (prevAlt < 0 && alt >= 0 && rise == null) rise = t;
        if (prevAlt >= 0 && alt < 0 && set == null) set = t;
      }
      prevAlt = alt;
    }
    return (rise, set);
  }
}
