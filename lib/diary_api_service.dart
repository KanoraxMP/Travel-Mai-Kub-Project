import 'dart:convert';
import 'package:http/http.dart' as http;

class DiaryApiService {
  static const String studentId = '66011212097';

  static const String baseUrl =
      'https://thipwimon.comsciproject.net/mydiary/api.php/$studentId';

  static Future<List<dynamic>> getDiaries() async {
    final response = await http.get(
      Uri.parse(baseUrl),
    ).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data;
    } else {
      throw Exception(
        'ไม่สามารถดึงข้อมูล Diary ได้',
      );
    }
  }

  static Future<void> createDiary(
    String title,
    String content,
    String mood,
    String date,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'mood': mood,
        'date': date,
      }),
    ).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'ไม่สามารถเพิ่ม Diary ได้',
      );
    }
  }

  static Future<void> updateDiary(
    String id,
    String title,
    String content,
    String mood,
    String date,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'mood': mood,
        'date': date,
      }),
    ).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'ไม่สามารถแก้ไข Diary ได้',
      );
    }
  }

  static Future<void> deleteDiary(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
    ).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'ไม่สามารถลบ Diary ได้'
        'status: ${response.statusCode}, '
        'response: ${response.body}',
      );
    }
  }
}