class WeatherModel {
  final double latitude;
  final double longitude;
  final double temperature;

  WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.temperature,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      temperature:
          (json['current']['temperature_2m'] as num).toDouble(),
    );
  }
}