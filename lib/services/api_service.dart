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

  /// Returns login data nếu thành công, hoặc null.
  /// [serverReachable] = true nếu server trả về response (kể cả lỗi 401),
  /// false nếu không kết nối được (mất mạng / timeout).
  static Future<({Map<String, dynamic>? data, bool serverReachable})> login(String u, String p) async {
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
      debugPrint('Login Status: \${res.statusCode}');
      if (res.statusCode == 200) {
        return (data: jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>, serverReachable: true);
      }
      // Server đang chạy nhưng từ chối (sai pass/user) → KHÔNG fallback offline
      return (data: null, serverReachable: true);
    } catch (e) {
      debugPrint('Login error: \$e');
    }
    // Không kết nối được server → cho phép fallback offline
    return (data: null, serverReachable: false);
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
      final billMaps = bills.map((b) {
        final map = b.toMap();
        // Chuyển đổi các flag integer (0/1 cho SQLite) thành boolean thật
        // cho Java backend. Đồng thời gửi cả 2 tên field (isPaid + paid,
        // isSynced + synced) để tương thích với mọi cách Jackson serialize
        // Java Record và JavaBean.
        map['isSynced'] = true;
        map['synced'] = true;
        map['isPaid'] = b.isPaid;
        map['paid'] = b.isPaid;
        return map;
      }).toList();

      final res = await http.post(
        Uri.parse('$baseUrl/sync/bills'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bills': billMaps}),
      );
      debugPrint('SyncBills status: ${res.statusCode}, body: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Sync error: $e');
    }
    return false;
  }

  static Future<bool> changePassword(String username, String oldPass, String newPass, {String? token}) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final res = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: headers,
        body: jsonEncode({
          'username': username,
          'oldPassword': oldPass,
          'newPassword': newPass,
        }),
      );
      debugPrint('ChangePassword status: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ChangePassword error: $e');
    }
    return false;
  }

  /// Tạo khách hàng mới trên server. Trả về ID được server gán nếu thành công, null nếu thất bại.
  static Future<int?> createCustomer({
    required String code,
    required String name,
    required String address,
    required String phone,
    required int currentReading,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/customers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'name': name,
          'address': address,
          'phone': phone,
          'currentReading': currentReading,
          'status': 0,
        }),
      );
      debugPrint('CreateCustomer status: ${res.statusCode}, body: ${res.body}');
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['id'] as int?;
      }
    } catch (e) {
      debugPrint('CreateCustomer error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String username,
    required String fullName,
    required String email,
    required String phone,
    String? token,
  }) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';
      final res = await http.post(
        Uri.parse('$baseUrl/auth/update-profile'),
        headers: headers,
        body: jsonEncode({
          'username': username,
          'fullName': fullName,
          'email': email,
          'phone': phone,
        }),
      );
      debugPrint('UpdateProfile status: ${res.statusCode}');
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('UpdateProfile error: $e');
    }
    return null;
  }
}
