import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/database_helper.dart';
import '../../routes/app_routes.dart';
import 'package:intl/intl.dart';

class CustomerHistoryScreen extends StatefulWidget {
  final Customer customer;
  const CustomerHistoryScreen({super.key, required this.customer});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<BillingProvider>(context, listen: false).fetchBillsByCustomer(widget.customer.id ?? 1);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Lịch sử hóa đơn')),
      body: Consumer<BillingProvider>(
        builder: (context, billingProvider, _) {
          final List<Bill> bills = billingProvider.customerBills;
          final now = DateTime.now();

          // Hóa đơn nợ của các tháng cũ (chưa thanh toán, không thuộc tháng hiện tại)
          final unpaidOldBills = bills.where((b) {
            final isCurrentMonth = b.date.month == now.month && b.date.year == now.year;
            return !b.isPaid && !isCurrentMonth;
          }).toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildCustomerHeader(),
                _buildQuickStats(bills, currencyFormat),

                // Banner thu toàn bộ nợ cũ (chỉ hiện khi có nợ)
                if (unpaidOldBills.isNotEmpty)
                  _buildCollectAllDebtBanner(context, unpaidOldBills, currencyFormat),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Danh sách kỳ thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const Spacer(),
                      Text('${bills.length} bản ghi', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return _buildBillCard(bill, currencyFormat);
                  },
                ),
                const SizedBox(height: 20),
                _buildInfoNote(),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.customer.id}')),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Địa chỉ đăng ký thu tiền', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                  child: Text('MÃ KH: ${widget.customer.code}', style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(List<Bill> bills, NumberFormat format) {
    final totalDebt = bills
        .where((b) => !b.isPaid)
        .fold<double>(0.0, (sum, b) => sum + b.totalAmount);
    final avgConsumption = bills.isEmpty
        ? 0.0
        : bills.map((b) => b.consumption).reduce((a, b) => a + b) / bills.length;
    final debtColor = totalDebt > 0 ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statBox('Trung bình', '${avgConsumption.toStringAsFixed(1)} m³', Colors.blue),
          const SizedBox(width: 15),
          _statBox('Tổng nợ', totalDebt > 0 ? format.format(totalDebt) : 'Không nợ', debtColor),
        ],
      ),
    );
  }

  Widget _buildCollectAllDebtBanner(BuildContext context, List<Bill> unpaidOldBills, NumberFormat format) {
    final totalDebt = unpaidOldBills.fold<double>(0.0, (sum, b) => sum + b.totalAmount);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Còn ${unpaidOldBills.length} kỳ chưa thanh toán',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text(
                format.format(totalDebt),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Thu toàn bộ nợ cũ: đánh dấu tất cả hóa đơn nợ là đã thanh toán
                final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
                final syncProvider = Provider.of<SyncProvider>(context, listen: false);
                final billingProvider = Provider.of<BillingProvider>(context, listen: false);

                for (final bill in unpaidOldBills) {
                  await DatabaseHelper.instance.markBillAsPaid(bill.id!);
                }

                // fetchLocal() luôn thành công (không phụ thuộc API),
                // luôn tăng refreshKey → CustomerCard tự reload data từ SQLite
                await billingProvider.fetchBillsByCustomer(widget.customer.id ?? 1);
                await syncProvider.fetchUnsyncedBills();
                await customerProvider.fetchLocal();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thu ${unpaidOldBills.length} kỳ nợ cũ (${format.format(totalDebt)})'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFFFF1744)),
              label: const Text(
                'THU TOÀN BỘ NỢ CŨ',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF1744), fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );

  Widget _buildBillCard(Bill bill, NumberFormat format) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.withValues(alpha: 0.1))),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle), child: const Icon(Icons.calendar_month, color: Colors.blue, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tháng ${bill.date.month}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${bill.date.year}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: bill.isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bill.isPaid ? 'Đã TT' : 'Chưa TT',
                        style: TextStyle(color: bill.isPaid ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(bill.isSynced ? 'Đã sync' : 'Chưa sync', style: TextStyle(color: bill.isSynced ? Colors.blue : Colors.grey, fontSize: 9)),
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
                    _readingCol('CHỈ SỐ ĐẦU', '${bill.oldReading} m³'),
                    _readingCol('CHỈ SỐ CUỐI', '${bill.newReading} m³'),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.blue, size: 14),
                          const SizedBox(width: 8),
                          const Text('Tiêu thụ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                          const SizedBox(width: 8),
                          Text('${bill.consumption.toInt()} m³', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Thành tiền', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        Text(format.format(bill.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _readingCol(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    ],
  );

  Widget _buildInfoNote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(child: Text('Dữ liệu hiển thị dựa trên lịch sử đã ghi nhận trên thiết bị.', style: TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
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
