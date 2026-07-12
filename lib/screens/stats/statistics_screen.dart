import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/billing_provider.dart';
import '../../routes/app_routes.dart';
import '../../models/bill.dart';
import '../../models/customer.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    // Khởi tạo chọn khách hàng đầu tiên sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final List<Customer> customers = Provider.of<CustomerProvider>(context, listen: false).allCustomers;
      if (user?.role == 'user') {
        try {
          final matchingCustomer = customers.firstWhere((c) => c.code == user?.customerCode);
          setState(() => _selectedCustomerId = matchingCustomer.id);
        } catch (_) {
          if (customers.isNotEmpty) {
            setState(() => _selectedCustomerId = customers.first.id);
          }
        }
      } else {
        if (customers.isNotEmpty) {
          setState(() => _selectedCustomerId = customers.first.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final String updateTime = DateFormat('HH:mm, dd/MM/yyyy').format(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final bool isUser = user?.role == 'user';
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thống kê', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Consumer2<CustomerProvider, BillingProvider>(
        builder: (context, customerProvider, billingProvider, child) {
          final List<Customer> customers = customerProvider.allCustomers;
          if (customers.isEmpty) return const Center(child: Text('Không có dữ liệu khách hàng.'));
          
          final selectedId = isUser
              ? (customers.firstWhere((c) => c.code == user?.customerCode, orElse: () => customers.first).id)
              : (_selectedCustomerId ?? customers.first.id);
          final selectedCustomer = customers.firstWhere((c) => c.id == selectedId, orElse: () => customers.first);
          
          return FutureBuilder<List<Bill>>(
            future: billingProvider.getAllBills(),
            builder: (context, snapshot) {
              final List<Bill> allBills = snapshot.data ?? [];
              final customerBills = allBills.where((b) => b.customerId == selectedId).toList();
              
              // Chuẩn bị dữ liệu biểu đồ (6 tháng gần nhất)
              List<double> chartData = _generateChartData(customerBills);

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) _buildCustomerSelector(customers, selectedId!),
                    _buildOverviewHeader(selectedCustomer, updateTime, customerBills),
                    _buildInfoGrid(selectedCustomer, customerBills),
                    _buildChartSection(chartData),
                    _buildRecentHistorySection(customerBills),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            }
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context, user?.role),
    );
  }

  List<double> _generateChartData(List<Bill> bills) {
    // Lấy 6 tháng gần nhất. Nếu không đủ 6 bản ghi thì bù bằng dữ liệu 0 hoặc trung bình
    List<double> data = bills.take(6).map((b) => b.consumption).toList().reversed.toList();
    while (data.length < 6) {
      data.insert(0, 0.0);
    }
    return data;
  }

  Widget _buildCustomerSelector(List<Customer> customers, int selectedId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text('Chọn khách hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: customers.length,
            itemBuilder: (context, i) {
              final customer = customers[i];
              bool isSelected = selectedId == customer.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCustomerId = customer.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${customer.id}'),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        customer.name.split(' ').last,
                        style: TextStyle(
                          fontSize: 11, 
                          color: isSelected ? Colors.blue : Colors.black87, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewHeader(Customer customer, String time, List<Bill> bills) {
    final bool isSynced = bills.isEmpty || bills.every((b) => b.isSynced);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng quan: ${customer.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Cập nhật lúc $time', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSynced ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(isSynced ? Icons.check_circle : Icons.sync_problem, size: 14, color: isSynced ? Colors.green : Colors.orange),
                const SizedBox(width: 4),
                Text(
                  isSynced ? 'Đã đồng bộ' : 'Chưa đồng bộ', 
                  style: TextStyle(color: isSynced ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Customer customer, List<Bill> bills) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '');
    double totalConsumption = bills.fold(0, (sum, item) => sum + item.consumption);
    double totalCost = bills.fold(0, (sum, item) => sum + item.totalAmount);
    double avg = bills.isEmpty ? 0 : totalConsumption / bills.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        children: [
          _statCard(Icons.water_drop, 'Tổng tiêu thụ', '${totalConsumption.toInt()}', 'M³'),
          _statCard(Icons.payments_outlined, 'Tổng chi phí', currencyFormat.format(totalCost), 'VND'),
          _statCard(Icons.trending_up, 'Trung bình', avg.toStringAsFixed(1), 'M³/tháng'),
          _statCard(Icons.badge_outlined, 'Mã KH', customer.code, ''),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, String unit) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const Spacer(),
          Text(label, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey, fontSize: 10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.grey, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<double> chartPoints) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xu hướng tiêu thụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('Tiêu thụ 6 tháng gần nhất', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey, fontSize: 10)),
          const SizedBox(height: 25),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('T${v.toInt() + 1}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartPoints.asMap().entries.map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: Colors.blue.withValues(alpha: 0.8),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistorySection(List<Bill> bills) {
    if (bills.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text('Lịch sử gần đây', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...bills.take(3).map((bill) => _recentItem(bill)),
      ],
    );
  }

  Widget _recentItem(Bill bill) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiêu thụ: ${bill.consumption.toInt()} m³', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('dd/MM/yyyy').format(bill.date), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(currencyFormat.format(bill.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String? role) {
    final bool isUser = role == 'user';
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: isUser ? 0 : 3, // highlight Trang chủ for user, Cài đặt for staff
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (isUser) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.history);
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.settings);
        } else {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.customerList);
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.history);
          if (index == 3) Navigator.pushReplacementNamed(context, AppRoutes.settings);
        }
      },
      items: isUser
          ? const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
            ]
          : const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
              BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Khách hàng'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
              BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
            ],
    );
  }
}
