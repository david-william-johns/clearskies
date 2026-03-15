class CurrentWeather {
  final double temperature;
  final int cloudCover;
  final double windSpeedKmh;
  final int humidity;
  final int precipitationProbability;

  const CurrentWeather({
    required this.temperature,
    required this.cloudCover,
    required this.windSpeedKmh,
    required this.humidity,
    required this.precipitationProbability,
  });
}
