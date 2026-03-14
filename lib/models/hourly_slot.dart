class HourlySlot {
  final DateTime time;

  // Cloud cover (0–100%)
  final int cloudCoverTotal;
  final int cloudCoverLow;
  final int cloudCoverMid;
  final int cloudCoverHigh;

  // Atmospheric
  final int humidity;
  final double windSpeedKnots;
  final int precipitationProbability;
  final double dewPoint;
  final double temperature;

  // Astronomy-specific (from 7timer, 1–5 scale)
  final int seeing; // 5=best, 1=worst
  final int transparency; // 5=best, 1=worst

  // Moon (calculated)
  final double moonAltitudeDeg;

  const HourlySlot({
    required this.time,
    required this.cloudCoverTotal,
    required this.cloudCoverLow,
    required this.cloudCoverMid,
    required this.cloudCoverHigh,
    required this.humidity,
    required this.windSpeedKnots,
    required this.precipitationProbability,
    required this.dewPoint,
    required this.temperature,
    required this.seeing,
    required this.transparency,
    required this.moonAltitudeDeg,
  });

  /// ClearSky score 0–100 for this hour.
  int get clearSkyScore {
    // Cloud cover: 0% = 100pts, 100% = 0pts
    final cloudScore = (100 - cloudCoverTotal).clamp(0, 100).toDouble();

    // Seeing: 1–5 → 0–100
    final seeingScore = ((seeing - 1) / 4 * 100).clamp(0, 100);

    // Transparency: 1–5 → 0–100
    final transScore = ((transparency - 1) / 4 * 100).clamp(0, 100);

    // Moon: above horizon degrades score proportionally (max penalty 50pts)
    final moonPenalty = moonAltitudeDeg > 0
        ? (moonAltitudeDeg / 90 * 50).clamp(0, 50)
        : 0.0;
    final moonScore = (100 - moonPenalty).clamp(0, 100);

    // Humidity: >80% starts penalising
    final humidScore = humidity <= 70
        ? 100.0
        : humidity <= 90
            ? ((90 - humidity) / 20 * 100).clamp(0, 100)
            : 0.0;

    // Wind: >15 knots degrades, >25 bad
    final windScore = windSpeedKnots <= 10
        ? 100.0
        : windSpeedKnots <= 25
            ? ((25 - windSpeedKnots) / 15 * 100).clamp(0, 100)
            : 0.0;

    final score = cloudScore * 0.40 +
        seeingScore * 0.25 +
        transScore * 0.20 +
        moonScore * 0.10 +
        humidScore * 0.03 +
        windScore * 0.02;

    return score.round().clamp(0, 100);
  }

  bool get isDewRisk => humidity >= 70;
  bool get isWindy => windSpeedKnots >= 15;
}
