import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() { _check(); }

  Future<void> _check() async {
    _user = await _db.getLastSession();
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
      try {
    _isLoading = true;
    notifyListeners();
    // 1. Gọi API Online thật
    final response = await ApiService.login(username, password);

    if (response.data != null) {
      final userData = response.data!['user'];
      final token = response.data!['token'];

      _user = User(
        username: userData['username'],
        fullName: userData['fullName'],
        role: userData['role'],
        email: userData['email'],
        phone: userData['phone'],
        customerCode: userData['customerCode'],
      );
      
      // Lưu session vào SQLite để dùng offline
      await _db.saveSession(_user!, token);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } else if (!response.serverReachable) {
      // Mất mạng hoàn toàn → fallback offline (chỉ kiểm tra username)
      final last = await _db.getLastSession();
      if (last != null && last.username == username) {
        _user = last; 
        _isLoading = false; 
        notifyListeners();
        return true;
      }
    }
    // Server từ chối (sai mật khẩu) → không cho phép đăng nhập
    _isLoading = false; 
    notifyListeners();
    return false;
    } catch (e, s) {
    debugPrint("LOGIN ERROR: $e");
    debugPrint(s.toString());
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
  }

  Future<bool> updateProfile(String name, String email, String phone) async {
    if (_user == null) return false;
    _isLoading = true; 
    notifyListeners();
    try {
      final db = DatabaseHelper.instance;
      final dbInstance = await db.database;
      final rows = await dbInstance.query(
        'user_session',
        columns: ['token'],
        where: 'username = ?',
        whereArgs: [_user!.username],
        limit: 1,
      );
      final token = rows.isNotEmpty ? rows.first['token'] as String? : null;

      final result = await ApiService.updateProfile(
        username: _user!.username,
        fullName: name,
        email: email,
        phone: phone,
        token: token,
      );

      if (result != null) {
        _user = User(
          username: result['username'] ?? _user!.username,
          fullName: result['fullName'] ?? name,
          role: result['role'] ?? _user!.role,
          email: result['email'] ?? email,
          phone: result['phone'] ?? phone,
          customerCode: result['customerCode'] ?? _user!.customerCode,
        );
        await _db.saveSession(_user!, token);
        _isLoading = false; 
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('updateProfile error: $e');
    }
    _isLoading = false; 
    notifyListeners();
    return false;
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      // Lấy token đang lưu trong session để gửi lên API
      final db = DatabaseHelper.instance;
      final dbInstance = await db.database;
      final rows = await dbInstance.query(
        'user_session',
        columns: ['token'],
        where: 'username = ?',
        whereArgs: [_user!.username],
        limit: 1,
      );
      final token = rows.isNotEmpty ? rows.first['token'] as String? : null;

      final success = await ApiService.changePassword(
        _user!.username,
        oldPass,
        newPass,
        token: token,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('changePassword error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null; 
    await _db.clearSession(); 
    notifyListeners();
  }
}
