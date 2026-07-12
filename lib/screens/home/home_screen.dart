import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../providers/customer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/billing_provider.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../models/user.dart';
import '../../routes/app_routes.dart';
import '../../core/utils/formatter_utils.dart';
import '../../core/constants/app_strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, dynamic>> _getHanoiWeather() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=21.0285&longitude=105.8542&current=temperature_2m,weather_code'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'temp': '${data['current']['temperature_2m'].round()}°C',
          'code': data['current']['weather_code'],
        };
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
    }
    return {'temp': '--°C', 'code': -1};
  }

  Widget _buildWeatherCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getHanoiWeather(),
      builder: (context, snapshot) {
        IconData weatherIcon = Icons.wb_sunny;
        Color iconColor = Colors.orange;
        String temperature = '--°C';

        if (snapshot.hasData) {
          temperature = snapshot.data!['temp'];
          int code = snapshot.data!['code'];

          if (code == 0) {
            weatherIcon = Icons.wb_sunny;
            iconColor = Colors.orange;
          } else if (code >= 1 && code <= 3) {
            weatherIcon = Icons.wb_cloudy;
            iconColor = Colors.blueGrey;
          } else if (code >= 51 && code <= 67) {
            weatherIcon = Icons.umbrella;
            iconColor = Colors.blue;
          } else if (code >= 95) {
            weatherIcon = Icons.thunderstorm;
            iconColor = Colors.deepPurple;
          } else if (code == -1) {
            // Fallback based on time if API fails
            final hour = DateTime.now().hour;
            if (hour >= 18 || hour < 6) {
              weatherIcon = Icons.nightlight_round;
              iconColor = Colors.indigo;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(weatherIcon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Hà Nội', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(temperature, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.1)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = FormatterUtils.formatDate(DateTime.now(), pattern: 'EEEE, d MMMM, yyyy');
    final user = Provider.of<AuthProvider>(context).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, user?.fullName ?? 'Người dùng', user?.role ?? 'user'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Chào ${user?.fullName}👋',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildWeatherCard(),
                      ],
                    ),
                    Text('Hôm nay: $formattedDate', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 20),
                    if (user?.role != 'user') _buildReadyBanner(context),
                    const SizedBox(height: 20),
                    if (user?.role == 'staff') _buildStaffStats(context),
                    if (user?.role == 'user') _buildUserHeader(context, user),
                    const SizedBox(height: 30),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CHỨC NĂNG CHÍNH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Xem tất cả', style: TextStyle(color: Colors.blue, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildFunctionGrid(context, user?.role ?? 'user'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, user?.role ?? 'user'),
    );
  }

  Widget _buildAppBar(BuildContext context, String name, String role) {
    String roleLabel = role == 'staff' ? 'Nhân viên' : 'Khách hàng';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(AppStrings.appName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(roleLabel, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name.trim()[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffStats(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final List<Customer> customers = provider.allCustomers;
        final pendingCount = customers.where((c) => !provider.recordedCustomerCodes.contains(c.code)).length;
        final completedCount = customers.where((c) => provider.recordedCustomerCodes.contains(c.code)).length;
        
        return Row(
          children: [
            _buildStatCard(context, '$pendingCount', 'CHƯA GHI', Colors.orange, 0),
            const SizedBox(width: 15),
            _buildStatCard(context, '$completedCount', 'HOÀN TẤT', Colors.green, 1),
          ],
        );
      },
    );
  }

  Widget _buildUserHeader(BuildContext context, User? user) {
    if (user == null) return const SizedBox();

    return FutureBuilder<List<Bill>>(
      future: Provider.of<BillingProvider>(context, listen: false).getAllBills(),
      builder: (context, snapshot) {
        double totalUnpaid = 0;
        String dueDateStr = '';
        bool hasDebt = false;

        if (snapshot.hasData && snapshot.data != null) {
          // Chỉ tính hóa đơn của CHÍNH khách hàng này và CHƯA thanh toán
          final unpaidBills = snapshot.data!
              .where((b) => b.customerCode == user.customerCode && !b.isPaid)
              .toList();

          if (unpaidBills.isNotEmpty) {
            totalUnpaid = unpaidBills.fold(0.0, (sum, b) => sum + b.totalAmount);
            hasDebt = true;

            // Hạn thanh toán: ngày 3 của tháng TIẾP THEO
            final now = DateTime.now();
            final dueDate = DateTime(now.year, now.month + 1, 3);
            dueDateStr = FormatterUtils.formatDate(dueDate, pattern: 'dd/MM/yyyy');
          }
        }

        final formattedAmount = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalUnpaid);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: hasDebt
                ? const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0288D1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: (hasDebt ? Colors.blue : Colors.green).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasDebt ? Icons.receipt_long : Icons.check_circle_outline,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasDebt ? 'Số tiền cần thanh toán' : 'Trạng thái thanh toán',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hasDebt ? formattedAmount : 'Đã thanh toán đầy đủ ✓',
                style: TextStyle(
                  fontSize: hasDebt ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (hasDebt) ...
              [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⏰ Hạn thanh toán: $dueDateStr',
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadyBanner(BuildContext context) {
    final syncProvider = Provider.of<SyncProvider>(context);
    final lastSyncTime = syncProvider.lastSyncTime;
    final String lastSync = lastSyncTime != null 
        ? DateFormat('HH:mm a').format(lastSyncTime)
        : 'Chưa đồng bộ';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dữ liệu đã sẵn sàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Đồng bộ lần cuối: $lastSync', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green)),
            child: const Text('Ổn định', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, Color color, int tabIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.customerList, arguments: {'tabIndex': tabIndex}),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
            borderRadius: BorderRadius.circular(15), 
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), 
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, color: color, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFunctionGrid(BuildContext context, String role) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final List<Customer> customers = provider.allCustomers;
        final pendingCount = customers.where((c) => !provider.recordedCustomerCodes.contains(c.code)).length;
        
        // Đọc SyncProvider để đếm số lượng hóa đơn chưa đồng bộ
        final syncProvider = Provider.of<SyncProvider>(context);
        final unsyncedCount = syncProvider.unsyncedBills.length;
        
        List<Widget> cards = [];
        
        if (role == 'staff') {
          cards = [
            _funcCard(context, 'Khách hàng', 'Danh sách hộ dân & ghi chỉ số nước', Icons.people_outline, Colors.blue, AppRoutes.customerList, hasBadge: true, badgeValue: '$pendingCount'),
            _funcCard(context, 'Đồng bộ', 'Tải lên kết quả & cập nhật dữ liệu', Icons.sync, Colors.green, AppRoutes.sync, hasBadge: unsyncedCount > 0, badgeValue: '$unsyncedCount'),
            _funcCard(context, 'Thống kê', 'Báo cáo sản lượng & hiệu suất thu', Icons.bar_chart, Colors.purple, AppRoutes.statistics),
            _funcCard(context, 'Lịch sử', 'Nhật ký hoạt động & biên lai đã xuất', Icons.history, Colors.grey, AppRoutes.history),
          ];
        } else {
          // Khách hàng thường: chỉ 2 menu — Lịch sử & Thống kê
          cards = [
            _funcCard(context, 'Lịch sử', 'Lịch sử sử dụng nước & thanh toán của bạn', Icons.history, Colors.blue, AppRoutes.history),
            _funcCard(context, 'Thống kê', 'Biểu đồ tiêu thụ & chi phí của bạn', Icons.bar_chart, Colors.purple, AppRoutes.statistics),
          ];
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: cards,
        );
      },
    );
  }

  Widget _funcCard(BuildContext context, String title, String desc, IconData icon, Color color, String route, {bool hasBadge = false, String badgeValue = '0'}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc, 
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey[600], 
                        fontSize: 11,
                        height: 1.2,
                      ), 
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              if (hasBadge)
                Positioned(
                  right: 12, top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red, 
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Center(
                      child: Text(badgeValue, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String role) {
    if (role == 'user') {
      // Khách hàng: chỉ Home, Lịch sử, Cài đặt
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.history);
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.settings);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
        ],
      );
    }

    // Staff / admin: đầy đủ menu
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) return;
        if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.customerList);
        if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.history);
        if (index == 3) Navigator.pushReplacementNamed(context, AppRoutes.settings);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Khách hàng'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
      ],
    );
  }
}
