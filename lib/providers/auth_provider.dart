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

    if (response != null) {
      final userData = response['user'];
      final token = response['token'];

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
    } else {
      final last = await _db.getLastSession();
      if (last != null && last.username == username) {
        _user = last; 
        _isLoading = false; 
        notifyListeners();
        return true;
      }
    }
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
    // Simulate API update
    await Future.delayed(const Duration(milliseconds: 500));
    _user = User(
      username: _user!.username,
      fullName: name,
      role: _user!.role,
      email: email,
      phone: phone,
    );
    await _db.saveSession(_user!, null);
    _isLoading = false; 
    notifyListeners();
    return true;
  }

  Future<bool> changePassword(String oldPass, String newPass) async {
    _isLoading = true; 
    notifyListeners();
    // Simulate API update
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false; 
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _user = null; 
    await _db.clearSession(); 
    notifyListeners();
  }
}
