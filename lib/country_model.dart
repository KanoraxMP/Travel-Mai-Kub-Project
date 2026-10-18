class CountryModel {
  final String name;
  final String capital;
  final String region;
  final int population;

  CountryModel({
    required this.name,
    required this.capital,
    required this.region,
    required this.population,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    final capitals = json['capitals'] as List<dynamic>?;

    return CountryModel(
      name: json['names']['common'] ?? 'ไม่มีข้อมูล',
      capital: capitals != null && capitals.isNotEmpty
          ? capitals[0]['name'] ?? 'ไม่มีข้อมูล'
          : 'ไม่มีข้อมูล',
      region: json['region'] ?? 'ไม่มีข้อมูล',
      population: (json['population'] as num?)?.toInt() ?? 0,
    );
  }
}