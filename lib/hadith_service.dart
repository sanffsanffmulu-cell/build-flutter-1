import 'dart:convert';
import 'package:http/http.dart' as http;

class HadithService {
  static const String baseUrl = 'https://hadis-api-id.vercel.app';

  // Mendapatkan hadits random
  static Future<Map<String, dynamic>> getRandomHadith() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hadith/random'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load hadith');
      }
    } catch (e) {
      print('Error fetching hadith: $e');
      return _getFallbackHadith();
    }
  }

  // Mendapatkan hadits berdasarkan kitab dan nomor
  static Future<Map<String, dynamic>> getHadith(String kitab, int nomor) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hadith/$kitab/$nomor'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load hadith');
      }
    } catch (e) {
      print('Error fetching hadith: $e');
      return _getFallbackHadith();
    }
  }

  // Hadits cadangan jika API error
  static Map<String, dynamic> _getFallbackHadith() {
    return {
      'kitab': 'Muslim',
      'nomor': 2,
      'judul': 'Keutamaan Dunia bagi Mukmin',
      'arab': 'الدنيا سجن المؤمن وجنة الكافر',
      'terjemahan': 'Rasulullah ﷺ bersabda: "Dunia adalah penjara bagi orang mukmin dan surga bagi orang kafir."',
      'sumber': 'HR. Muslim no. 2'
    };
  }
}