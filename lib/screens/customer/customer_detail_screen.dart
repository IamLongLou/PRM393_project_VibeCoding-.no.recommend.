import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../providers/customer_provider.dart';
import '../../services/database_helper.dart';
import '../../routes/app_routes.dart';
import 'customer_history_screen.dart';
import 'meter_reading_screen.dart';
import 'route_optimization_screen.dart';
import 'receipt_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  Future<void> _makeCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _sendSMS(String phone) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openMap(String address) async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";
    final Uri launchUri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Chi tiết KH'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, _) {
          final isRecordedThisMonth = customerProvider.recordedCustomerCodes.contains(customer.code);
          return FutureBuilder<List<Bill>>(
            key: ValueKey('detail_${customer.id}_${customerProvider.refreshKey}'),
            future: DatabaseHelper.instance.getBillsByCustomer(customer.id!),
            builder: (context, snapshot) {
              final bills = snapshot.data ?? [];
              final now = DateTime.now();

              // Hóa đơn của tháng hiện tại (nếu có)
              Bill? currentMonthBill;
              try {
                currentMonthBill = bills.firstWhere(
                  (b) => b.date.month == now.month && b.date.year == now.year,
                );
              } catch (_) {}

              // Hóa đơn gần nhất bất kỳ (dùng cho _buildMainReadingCard)
              Bill? latestBill;
              if (bills.isNotEmpty) latestBill = bills.first;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 25),
                    _buildMainReadingCard(latestBill),
                    const SizedBox(height: 20),
                    _buildLocationSection(context),
                    const SizedBox(height: 20),
                    _buildHistoryAccess(context),
                    const SizedBox(height: 30),
                    _buildActionButton(context, isRecordedThisMonth, currentMonthBill),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(radius: 45, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${customer.id}')),
            Positioned(
              right: 5,
              bottom: 5,
              child: CircleAvatar(
                radius: 8,
                backgroundColor: Colors.green,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(customer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('KH · ${customer.code}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Text('Hộ gia đình', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionIcon(Icons.call_outlined, 'Gọi điện', () => _makeCall(customer.phone)),
        const SizedBox(width: 30),
        _actionIcon(Icons.chat_bubble_outline, 'Nhắn tin', () => _sendSMS(customer.phone)),
        const SizedBox(width: 30),
        _actionIcon(Icons.info_outline, 'Hỗ trợ', () {}),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
          child: Icon(icon, color: Colors.blue, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Widget _buildMainReadingCard(Bill? latestBill) {
    final lastMonthConsumption = latestBill != null ? '${latestBill.consumption.toInt()} m³' : 'N/A';
    final lastReadingDate = latestBill != null ? DateFormat('dd/MM/yyyy').format(latestBill.date) : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CHỈ SỐ HIỆN TẠI', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('${customer.currentReading} m³', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.water_drop, color: Colors.white, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              const Text('THÁNG TRƯỚC', style: TextStyle(color: Colors.white60, fontSize: 10)),
              const SizedBox(width: 5),
              Text(lastMonthConsumption, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              const Text('GHI GẦN NHẤT', style: TextStyle(color: Colors.white60, fontSize: 10)),
              const SizedBox(width: 5),
              Text(lastReadingDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1))
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.location_on, color: Colors.blue, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Vị trí lắp đặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(customer.address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () => _openMap(customer.address),
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: NetworkImage('https://maps.gstatic.com/tactile/pane/default_geocode-2x.png'), 
                  fit: BoxFit.cover,
                  opacity: 0.5,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Mở Google Maps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryAccess(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1))
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerHistoryScreen(customer: customer))),
        child: Row(
          children: [
            const Icon(Icons.history, color: Colors.grey, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Lịch sử tiêu thụ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
              child: const Text('12 tháng', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool isRecordedThisMonth, Bill? currentMonthBill) {
    final isPaid = currentMonthBill?.isPaid ?? false;

    // Xác định màu sắc và nhãn nút theo trạng thái tháng hiện tại
    Color btnColor;
    IconData btnIcon;
    String btnLabel;
    VoidCallback? btnAction;

    if (!isRecordedThisMonth) {
      // Chưa ghi số tháng này
      btnColor = Colors.blue;
      btnIcon = Icons.edit_note;
      btnLabel = 'Ghi chỉ số mới';
      btnAction = () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeterReadingScreen(customer: customer)));
    } else if (!isPaid) {
      // Đã ghi số nhưng KH chưa thanh toán
      btnColor = Colors.orange;
      btnIcon = Icons.receipt_long;
      btnLabel = 'Xem hóa đơn – Chờ thanh toán';
      btnAction = currentMonthBill != null
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(customer: customer, bill: currentMonthBill)))
          : null;
    } else {
      // Đã ghi số và KH đã thanh toán xong
      btnColor = Colors.green;
      btnIcon = Icons.check_circle_outline;
      btnLabel = 'Xem biên lai đã thanh toán';
      btnAction = currentMonthBill != null
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(customer: customer, bill: currentMonthBill)))
          : null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: btnAction,
              icon: Icon(btnIcon, size: 24),
              label: Text(btnLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => RouteOptimizationScreen(customer: customer))
              ),
              icon: const Icon(Icons.directions_outlined, size: 22),
              label: const Text('Chỉ đường'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: const BorderSide(color: Color(0xFF2196F3)),
                foregroundColor: const Color(0xFF2196F3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1, // Thuộc phần Khách hàng
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
