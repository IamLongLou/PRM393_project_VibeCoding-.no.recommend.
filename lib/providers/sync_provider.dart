import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';
import 'customer_provider.dart';

class SyncProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Bill> _unsynced = [];
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastError;

  List<Bill> get unsyncedBills => _unsynced;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;

  SyncProvider() {
    fetchUnsyncedBills();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? timeString = prefs.getString('lastSyncTime');
    if (timeString != null) {
      _lastSyncTime = DateTime.tryParse(timeString);
      notifyListeners();
    }
  }

  Future<void> fetchUnsyncedBills() async {
    _unsynced = await _db.getUnsyncedBills();
    notifyListeners();
  }

  /// Đồng bộ toàn bộ hóa đơn chưa sync lên SQL Server.
  /// [customerProvider] sẽ được reload sau khi sync thành công
  /// để danh sách khách hàng phản ánh trạng thái mới nhất.
  Future<bool> syncAll(CustomerProvider customerProvider) async {
    if (_unsynced.isEmpty) return true;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // 1. Đẩy hóa đơn lên SQL Server
      final response = await ApiService.syncBills(_unsynced);

      if (response) {
        // 2. Đánh dấu isSynced = 1 trong SQLite
        await _db.markBillsAsSynced(_unsynced);

        // 3. Clear danh sách unsynced
        _unsynced = [];

        // 4. Lưu thời gian sync
        _lastSyncTime = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('lastSyncTime', _lastSyncTime!.toIso8601String());

        // 5. QUAN TRỌNG: Reload danh sách KH từ SQLite để UI cập nhật trạng thái.
        //    Sau khi server nhận bill và set customer.status=COMPLETED,
        //    ta cần gọi refresh() để lấy trạng thái mới về và update SQLite.
        await customerProvider.refresh();

        _isSyncing = false;
        notifyListeners();
        return true;
      } else {
        _lastError = 'Server từ chối đồng bộ. Vui lòng thử lại.';
      }
    } catch (e) {
      _lastError = 'Lỗi kết nối: $e';
      debugPrint('SyncProvider.syncAll error: $e');
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }
}
