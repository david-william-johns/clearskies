class AppLocation {
  final double latitude;
  final double longitude;
  final String displayName;
  final String? postcode;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    this.postcode,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'displayName': displayName,
        'postcode': postcode,
      };

  factory AppLocation.fromJson(Map<String, dynamic> json) => AppLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        displayName: json['displayName'] as String,
        postcode: json['postcode'] as String?,
      );

  @override
  String toString() => displayName;
}
