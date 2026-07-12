import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Thêm để dùng kIsWeb
import '../models/bill.dart';

class ApiService {
  // Tự động chọn URL phù hợp: Web dùng localhost, Android dùng 10.0.2.2
  // Thử bỏ /api nếu backend của bạn không có context-path này
  static String get baseUrl => kIsWeb 
    ? 'http://localhost:8080/api' 
    : 'http://10.0.2.2:8080/api';

  static Future<Map<String, dynamic>?> login(String u, String p) async {
    try {
      debugPrint('Calling Login: $baseUrl/auth/login');
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'), 
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        }, 
        body: jsonEncode({'username': u, 'password': p})
      );
      debugPrint('Login Status: ${res.statusCode}');
      if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> bootstrap() async {
    try {
      debugPrint('Calling Bootstrap: $baseUrl/bootstrap');
      final res = await http.get(Uri.parse('$baseUrl/bootstrap'));
      debugPrint('Bootstrap Status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        debugPrint('Data received: ${data['customers']?.length} customers');
        return data;
      }
    } catch (e) {
      debugPrint('Bootstrap error: $e');
    }
    return null;
  }

  static Future<bool> syncBills(List<Bill> bills) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/sync/bills'), 
        headers: {'Content-Type': 'application/json'}, 
        body: jsonEncode({'bills': bills.map((b) => b.toMap()..['isSynced'] = 1).toList()})
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Sync error: $e');
    }
    return false;
  }
}
