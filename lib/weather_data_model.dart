class WeatherDataModel {
  final int? id;
  final double latitude;
  final double longitude;
  final double temperature;
  final String fetchedAt;

  WeatherDataModel({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.fetchedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'fetchedAt': fetchedAt,
    };
  }

  factory WeatherDataModel.fromMap(Map<String, dynamic> map) {
    return WeatherDataModel(
      id: map['id'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      temperature: (map['temperature'] as num).toDouble(),
      fetchedAt: map['fetchedAt'],
    );
  }
}