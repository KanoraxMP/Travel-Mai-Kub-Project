import 'dart:convert';
import 'package:http/http.dart' as http;
import 'weather_model.dart';

class ApiService {
  Future<WeatherModel> getWeather() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=13.75&longitude=100.5&current=temperature_2m',
    );

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        return WeatherModel.fromJson(
          jsonDecode(response.body),
        );
      } else {
        throw Exception('ไม่สามารถดึงข้อมูลสภาพอากาศได้');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเชื่อมต่อ: $e');
    }
  }
}