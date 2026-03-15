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
    return (_fromJulian(jSet), _fromJulian(jRise + 1));
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

  // ─── Planet positions (Meeus low-precision orbital elements) ────────────────

  // Orbital elements at J2000.0: [L0, L1, a, e0, e1, i, Omega, omega, M0, M1]
  // L0/L1 = mean longitude and rate (°/day)
  // e0/e1 = eccentricity and rate
  // i = inclination, Omega = long. ascending node, omega = long. perihelion
  // M0/M1 = mean anomaly and rate
  // Source: Meeus "Astronomical Algorithms" ch.33 simplified elements
  static const Map<String, List<double>> _planetElements = {
    'Mercury': [252.2503, 4.0923344, 0.38710, 0.20563069, 0.0, 7.005, 48.331, 77.456, 174.7948, 4.0923344],
    'Venus':   [181.9798, 1.6021302, 0.72332, 0.00677323, 0.0, 3.395, 76.680, 131.564, 50.4161, 1.6021302],
    'Mars':    [355.4330, 0.5240207, 1.52366, 0.09341233, 0.0, 1.850, 49.558, 336.060, 19.3730, 0.5240207],
    'Jupiter': [ 34.3515, 0.0830853, 5.20260, 0.04849485, 0.0, 1.303, 100.464, 14.331, 20.0202, 0.0830853],
    'Saturn':  [ 50.0774, 0.0334442, 9.55491, 0.05550825, 0.0, 2.489, 113.666, 93.057, 317.0207, 0.0334442],
  };

  /// Returns the altitude in degrees of [planet] at [lat]/[lon] at [time].
  /// [planet] must be one of: Mercury, Venus, Mars, Jupiter, Saturn.
  /// Returns null if planet is unknown.
  double? planetAltitude({
    required String planet,
    required double lat,
    required double lon,
    required DateTime time,
  }) {
    final el = _planetElements[planet];
    if (el == null) return null;

    final d = _toDays(time.toUtc());

    // Earth's heliocentric coordinates (simplified)
    final mSun = (357.5291 + 0.98560028 * d) * _rad;
    final lSun = (280.4665 + 0.9856474 * d) * _rad;
    final c = (1.9148 * sin(mSun) + 0.02 * sin(2 * mSun)) * _rad;
    final lambdaSun = lSun + c + pi;
    final earthX = cos(lambdaSun);
    final earthY = sin(lambdaSun) * cos(_e);
    final earthZ = sin(lambdaSun) * sin(_e);

    // Planet mean anomaly
    final M = ((el[8] + el[9] * d) % 360) * _rad;
    // Equation of centre (simplified)
    final v = M + 2 * el[3] * sin(M) + 1.25 * el[3] * el[3] * sin(2 * M);
    // Heliocentric ecliptic longitude (simplified)
    final omega = el[7] * _rad;
    final bigOmega = el[6] * _rad;
    final iRad = el[5] * _rad;
    final r = el[2] * (1 - el[3] * el[3]) / (1 + el[3] * cos(v));

    // Heliocentric ecliptic coordinates
    final u = v + omega - bigOmega;
    final pX = r * (cos(bigOmega) * cos(u) - sin(bigOmega) * sin(u) * cos(iRad));
    final pY = r * (sin(bigOmega) * cos(u) + cos(bigOmega) * sin(u) * cos(iRad));
    final pZ = r * sin(u) * sin(iRad);

    // Geocentric ecliptic coordinates (subtract Earth)
    final gX = pX - earthX;
    final gY = pY - earthY;
    final gZ = pZ - earthZ;

    // Convert to equatorial
    final ra = atan2(gY * cos(_e) - gZ * sin(_e), gX);
    final dec = asin((gY * sin(_e) + gZ * cos(_e)) /
        sqrt(gX * gX + gY * gY + gZ * gZ));

    // Compute altitude
    final phi = lat * _rad;
    final lw = -lon * _rad;
    final H = (280.16 + 360.9856235 * d) * _rad - lw - ra; // hour angle
    final alt = asin(sin(phi) * sin(dec) + cos(phi) * cos(dec) * cos(H));
    return alt / _rad;
  }

  /// Checks if [planet] is visible (altitude > [minAlt] degrees) at any point
  /// during astronomical darkness at [lat]/[lon] on [date].
  bool isPlanetVisibleOnNight({
    required String planet,
    required double lat,
    required double lon,
    required DateTime date,
    double minAlt = 10.0,
  }) {
    final (dusk, dawn) = getAstronomicalTwilight(lat: lat, lon: lon, forDate: date);
    if (dusk == null || dawn == null) return false;

    // Sample every hour during the dark window
    var t = dusk;
    while (t.isBefore(dawn)) {
      final alt = planetAltitude(planet: planet, lat: lat, lon: lon, time: t);
      if (alt != null && alt > minAlt) return true;
      t = t.add(const Duration(hours: 1));
    }
    return false;
  }

  // ─── Moon phase event scanning ───────────────────────────────────────────────

  /// Scans [from]…[from + days] for new moon and full moon crossings.
  /// Returns list of (date, phaseName) for each detected event.
  List<(DateTime, String)> findMoonPhaseEvents({
    required DateTime from,
    int days = 30,
  }) {
    final events = <(DateTime, String)>[];
    double? prev;
    for (int i = 0; i <= days; i++) {
      final d = from.add(Duration(days: i));
      final phase = moonPhase(d);
      if (prev != null) {
        // New moon: phase transitions through 0 (crosses from high ~0.97+ to low ~0.03-)
        if (prev > 0.85 && phase < 0.15) {
          events.add((d, 'New Moon'));
        }
        // Full moon: phase crosses 0.5
        if (prev < 0.48 && phase >= 0.5) {
          events.add((d, 'Full Moon'));
        } else if (prev >= 0.5 && phase < 0.52 && phase > 0.48) {
          // Already past 0.5 — ignore duplicates
        }
      }
      prev = phase;
    }
    return events;
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
