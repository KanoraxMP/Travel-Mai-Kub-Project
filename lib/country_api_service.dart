import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'country_model.dart';

class CountryApiService {
  Future<CountryModel> getThailand() async {
    final url = Uri.parse(
      'https://api.restcountries.com/countries/v5/codes.alpha_2/TH',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer rc_live_779b6982402c42499d633742056fde88',
        },
      ).timeout(
        const Duration(seconds: 10),
      );

      debugPrint(
        'Country API Status: ${response.statusCode}',
      );

      debugPrint(
        'Country API Response: ${response.body}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body);

        final List<dynamic> objects =
            data['data']['objects'];

        return CountryModel.fromJson(objects[0]);
      } else {
        throw Exception(
          'ไม่สามารถดึงข้อมูลประเทศได้',
        );
      }
    } catch (e) {
      throw Exception(
        'เกิดข้อผิดพลาดในการเชื่อมต่อ: $e',
      );
    }
  }
}