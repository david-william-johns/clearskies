import 'hourly_slot.dart';

class DayForecast {
  final DateTime date;
  final DateTime astronomicalDusk;
  final DateTime astronomicalDawn;
  final double moonPhase; // 0.0 = new, 0.5 = full, 1.0 = new again
  final DateTime? moonRise;
  final DateTime? moonSet;

  /// Only the hours that fall within the dark window (dusk → dawn).
  final List<HourlySlot> darkHourSlots;

  const DayForecast({
    required this.date,
    required this.astronomicalDusk,
    required this.astronomicalDawn,
    required this.moonPhase,
    required this.moonRise,
    required this.moonSet,
    required this.darkHourSlots,
  });

  /// Overall score for this night — average of dark-hour scores.
  int get clearSkyScore {
    if (darkHourSlots.isEmpty) return 0;
    final sum = darkHourSlots.fold(0, (acc, s) => acc + s.clearSkyScore);
    return (sum / darkHourSlots.length).round();
  }

  /// Best consecutive 2-hour window score during dark hours.
  int get peakScore {
    if (darkHourSlots.isEmpty) return 0;
    return darkHourSlots.map((s) => s.clearSkyScore).reduce((a, b) => a > b ? a : b);
  }

  /// Cloud cover percentage at the best (lowest cloud) dark hour.
  int get bestCloudCover {
    if (darkHourSlots.isEmpty) return 100;
    return darkHourSlots.map((s) => s.cloudCoverTotal).reduce((a, b) => a < b ? a : b);
  }

  Duration get darkDuration => astronomicalDawn.difference(astronomicalDusk);

  String get moonPhaseEmoji {
    if (moonPhase < 0.05 || moonPhase > 0.95) return '🌑';
    if (moonPhase < 0.20) return '🌒';
    if (moonPhase < 0.30) return '🌓';
    if (moonPhase < 0.45) return '🌔';
    if (moonPhase < 0.55) return '🌕';
    if (moonPhase < 0.70) return '🌖';
    if (moonPhase < 0.80) return '🌗';
    return '🌘';
  }

  String get moonPhaseName {
    if (moonPhase < 0.05 || moonPhase > 0.95) return 'New Moon';
    if (moonPhase < 0.20) return 'Wax. Crescent';
    if (moonPhase < 0.30) return 'First Quarter';
    if (moonPhase < 0.45) return 'Wax. Gibbous';
    if (moonPhase < 0.55) return 'Full Moon';
    if (moonPhase < 0.70) return 'Wan. Gibbous';
    if (moonPhase < 0.80) return 'Last Quarter';
    return 'Wan. Crescent';
  }

  int get moonIlluminationPct {
    // Approximate: illumination peaks at full moon (phase=0.5)
    final angle = (moonPhase * 2 * 3.14159265).abs();
    return ((1 - (angle / 3.14159265 - 1).abs()) * 100).round().clamp(0, 100);
  }
}
