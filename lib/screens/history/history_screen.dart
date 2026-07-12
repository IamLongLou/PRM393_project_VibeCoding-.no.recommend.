import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/bill.dart';
import '../../models/customer.dart';
import '../../routes/app_routes.dart';
import '../customer/receipt_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    final bool isUser = user?.role == 'user';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          isUser ? 'Lịch sử sử dụng & thanh toán' : 'Lịch sử thu tiền',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: isUser
          ? _buildCustomerHistoryBody(context, user?.customerCode, currencyFormat, isDark)
          : _buildStaffHistoryBody(context, currencyFormat, isDark),
      bottomNavigationBar: _buildBottomNav(context, user?.role),
    );
  }

  Widget _buildCustomerHistoryBody(
      BuildContext context, String? customerCode, NumberFormat currencyFormat, bool isDark) {
    if (customerCode == null || customerCode.isEmpty) {
      return const Center(child: Text('Không tìm thấy mã khách hàng.'));
    }

    return Consumer2<CustomerProvider, BillingProvider>(
      builder: (context, customerProvider, billingProvider, child) {
        if (customerProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = customerProvider.allCustomers;
        Customer? currentCustomer;
        try {
          currentCustomer = customers.firstWhere((c) => c.code == customerCode);
        } catch (_) {}

        if (currentCustomer == null) {
          return const Center(child: Text('Không tìm thấy thông tin khách hàng tương ứng.'));
        }

        return FutureBuilder<List<Bill>>(
          future: billingProvider.getAllBills(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allBills = snapshot.data ?? [];
            final customerBills = allBills.where((b) => b.customerCode == customerCode).toList();

            if (customerBills.isEmpty) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCustomerHeader(currentCustomer!, context, isDark),
                    const SizedBox(height: 40),
                    const Center(child: Text('Chưa có lịch sử sử dụng nước nào.')),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildCustomerHeader(currentCustomer!, context, isDark),
                  _buildQuickStats(customerBills, currencyFormat, context, isDark),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Danh sách kỳ thanh toán',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${customerBills.length} bản ghi',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: customerBills.length,
                    itemBuilder: (context, index) {
                      final bill = customerBills[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceiptScreen(customer: currentCustomer!, bill: bill),
                            ),
                          );
                        },
                        child: _buildBillCard(bill, currencyFormat, context, isDark),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildInfoNote(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStaffHistoryBody(BuildContext context, NumberFormat currencyFormat, bool isDark) {
    return Consumer<BillingProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<List<Bill>>(
          future: provider.getAllBills(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Chưa có lịch sử thu tiền nào.'));
            }

            final List<Bill> bills = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: bills.length,
              itemBuilder: (context, index) {
                final Bill bill = bills[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                  elevation: 0,
                  color: Theme.of(context).cardTheme.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: InkWell(
                    onTap: () {
                      try {
                        final List<Customer> customers =
                            Provider.of<CustomerProvider>(context, listen: false).allCustomers;
                        final Customer customer = customers.firstWhere((c) => c.id == bill.customerId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReceiptScreen(customer: customer, bill: bill),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không tìm thấy thông tin khách hàng')),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            child: const Icon(Icons.receipt_long, color: Colors.blue),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.billCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bill.customerName ?? 'N/A',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Mã KH: ${bill.customerCode ?? 'N/A'}',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(bill.date),
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(bill.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${bill.consumption.toInt()} m³',
                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerHeader(Customer customer, BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${customer.id}'),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  customer.address,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'MÃ KH: ${customer.code}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<Bill> bills, NumberFormat format, BuildContext context, bool isDark) {
    final totalDebt = bills.where((b) => !b.isPaid).fold<double>(0.0, (sum, b) => sum + b.totalAmount);
    final avgConsumption =
        bills.isEmpty ? 0.0 : bills.map((b) => b.consumption).reduce((a, b) => a + b) / bills.length;
    final debtColor = totalDebt > 0 ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          _statBox('Trung bình tiêu thụ', '${avgConsumption.toStringAsFixed(1)} m³', Colors.blue, isDark),
          const SizedBox(width: 15),
          _statBox('Tổng nợ hiện tại', totalDebt > 0 ? format.format(totalDebt) : 'Không có nợ', debtColor, isDark),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color, bool isDark) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildBillCard(Bill bill, NumberFormat format, BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tháng ${bill.date.month}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        '${bill.date.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: bill.isPaid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.isPaid ? 'Đã TT' : 'Chưa TT',
                        style: TextStyle(
                          color: bill.isPaid ? Colors.green : Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      bill.isSynced ? 'Đã sync' : 'Chưa sync',
                      style: TextStyle(
                        color: bill.isSynced ? Colors.blue : Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _readingCol('CHỈ SỐ ĐẦU', '${bill.oldReading} m³', isDark),
                    _readingCol('CHỈ SỐ CUỐI', '${bill.newReading} m³', isDark),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.blue, size: 14),
                          const SizedBox(width: 8),
                          const Text('Tiêu thụ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(width: 8),
                          Text(
                            '${bill.consumption.toInt()} m³',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Thành tiền', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(
                          format.format(bill.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _readingCol(String label, String value, bool isDark) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      );

  Widget _buildInfoNote(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dữ liệu hiển thị dựa trên lịch sử đã ghi nhận trên hệ thống thiết bị.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, String? role) {
    final bool isUser = role == 'user';
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: isUser ? 1 : 2,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (isUser) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (index == 1) return;
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.settings);
        } else {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.customerList);
          if (index == 2) return;
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

