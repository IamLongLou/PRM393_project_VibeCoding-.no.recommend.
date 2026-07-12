// lib/providers/connectivity_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _pollTimer;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check ngay khi khởi động
    await _checkRealInternet();

    // Lắng nghe khi OS báo đổi trạng thái interface (wifi/data/none...)
    // Dùng để kiểm tra lại NGAY khi có thay đổi, thay vì chờ hết chu kỳ poll
    _sub = Connectivity().onConnectivityChanged.listen((_) {
      _checkRealInternet();
    });

    // Đề phòng emulator không bắn event connectivity đúng lúc:
    // tự poll định kỳ để đảm bảo trạng thái luôn đúng thực tế
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkRealInternet();
    });
  }

  Future<void> _checkRealInternet() async {
    bool hasInternet;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      hasInternet = false;
    }

    if (hasInternet != _isOnline) {
      _isOnline = hasInternet;
      debugPrint('>>> ConnectivityProvider: isOnline = $_isOnline');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}