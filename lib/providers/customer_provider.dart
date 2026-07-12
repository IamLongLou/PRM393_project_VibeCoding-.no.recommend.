import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../services/database_helper.dart';
import '../services/api_service.dart';

class CustomerProvider with ChangeNotifier {
  final _db = DatabaseHelper.instance;
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String _searchQuery = "";
  DateTime? _lastSyncTime;

  /// Key tăng mỗi khi có thay đổi dữ liệu local → CustomerCard dùng để force re-run FutureBuilder
  int _refreshKey = 0;
  int get refreshKey => _refreshKey;

  List<Customer> get customers => _filteredCustomers.isEmpty && _searchQuery.isEmpty ? _customers : _filteredCustomers;
  List<Customer> get allCustomers => _customers;
  bool get isLoading => _isLoading;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Tập hợp mã KH đã được ghi số (lập hóa đơn) trong tháng hiện tại
  Set<String> _recordedCustomerCodes = {};
  Set<String> get recordedCustomerCodes => _recordedCustomerCodes;

  CustomerProvider() { fetch(); }

  /// Cập nhật tập hợp các mã khách hàng đã có hóa đơn trong tháng hiện tại
  Future<void> _updateRecordedCustomers() async {
    try {
      final bills = await _db.getAllBills();
      final now = DateTime.now();
      _recordedCustomerCodes = bills
          .where((b) => b.date.month == now.month && b.date.year == now.year)
          .map((b) => b.customerCode ?? '')
          .where((code) => code.isNotEmpty)
          .toSet();
      debugPrint('Recorded customer codes in current month (${now.month}/${now.year}): $_recordedCustomerCodes');
    } catch (e) {
      debugPrint('Error _updateRecordedCustomers: $e');
    }
  }

  /// Load ngay từ SQLite, rồi chạy ngầm refresh từ API
  Future<void> fetch() async {
    _isLoading = true;
    notifyListeners();

    // 1. Ưu tiên lấy từ SQLite để UI hiện lên ngay
    _customers = await _db.getAllCustomers();
    await _updateRecordedCustomers();
    _filteredCustomers = [];
    _isLoading = false;
    _refreshKey++;
    notifyListeners();

    // 2. Sau đó mới thử cập nhật từ API ở nền (không block UI)
    refresh();
  }

  /// Chỉ reload từ SQLite, KHÔNG gọi API.
  /// Dùng sau khi ghi số / cập nhật trạng thái để UI cập nhật ngay.
  Future<void> fetchLocal() async {
    _customers = await _db.getAllCustomers();
    await _updateRecordedCustomers();
    _filteredCustomers = [];
    _refreshKey++;
    debugPrint('CustomerProvider.fetchLocal: loaded ${_customers.length} customers from SQLite.');
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final data = await ApiService.bootstrap();
      if (data != null) {
        final List remoteC = data['customers'];
        final List remoteB = data['bills'];
        debugPrint('CustomerProvider.refresh: loaded ${remoteC.length} customers and ${remoteB.length} bills from API.');
        await _db.upsertCustomers(remoteC.map((e) => Customer.fromMap(e)).toList());
        for (var b in remoteB) {
          await _db.insertBill(Bill.fromMap(b).copyWith(isSynced: true));
        }
        _customers = await _db.getAllCustomers();
        await _updateRecordedCustomers();
        _lastSyncTime = DateTime.now();
        if (_searchQuery.isNotEmpty) searchCustomers(_searchQuery);
        _refreshKey++;
        debugPrint('CustomerProvider.refresh completed: in-memory size=${_customers.length}');
        notifyListeners();
      }
    } catch (e, s) {
      debugPrint("Refresh error: $e");
      debugPrint(s.toString());
    }
  }

  void searchCustomers(String q) {
    _searchQuery = q.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredCustomers = [];
    } else {
      _filteredCustomers = _customers.where((c) =>
        c.name.toLowerCase().contains(_searchQuery) ||
        c.code.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    notifyListeners();
  }
}
