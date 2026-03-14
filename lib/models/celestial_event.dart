enum CelestialEventType { meteorShower, aurora, planet, moon, orbital }

class CelestialEvent {
  final CelestialEventType type;
  final String name;
  final DateTime date;
  final String description;

  const CelestialEvent({
    required this.type,
    required this.name,
    required this.date,
    required this.description,
  });
}
