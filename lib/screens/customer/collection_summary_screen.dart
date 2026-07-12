import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../services/billing_service.dart';
import '../../services/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import 'receipt_screen.dart';

/// Màn hình Xác nhận và Tổng hợp Hóa đơn (Nghiệp vụ phức tạp & Chuyển dữ liệu)
class CollectionSummaryScreen extends StatelessWidget {
  final Customer customer;
  final Bill bill;

  const CollectionSummaryScreen({
    super.key,
    required this.customer,
    required this.bill,
  });

  @override
  Widget build(BuildContext context) {
    // Tính toán bóc tách bậc thang (Business Rule Visualization)
    int consumption = bill.newReading - bill.oldReading;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo hóa đơn"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCollectorInfo(context),
            const SizedBox(height: 20),
            _buildCustomerSection(),
            const SizedBox(height: 20),
            _buildBusinessRuleBreakdown(consumption),
            const SizedBox(height: 20),
            _buildTotalSection(),
            const SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectorInfo(BuildContext context) {
    final userName = context.read<AuthProvider>().user?.fullName ?? 'Nhân viên';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge, color: Colors.blue),
          const SizedBox(width: 10),
          const Text("Nhân viên thu: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(userName),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("THÔNG TIN KHÁCH HÀNG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRow("Tên khách hàng", customer.name),
                _buildRow("Mã khách hàng", customer.code),
                _buildRow("Chỉ số cũ", "${bill.oldReading} m³"),
                _buildRow("Chỉ số mới", "${bill.newReading} m³"),
                _buildRow("Tiêu thụ", "${bill.newReading - bill.oldReading} m³", isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Thể hiện nghiệp vụ phức tạp: Bóc tách tiền nước bậc thang
  Widget _buildBusinessRuleBreakdown(int consumption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CHI TIẾT BẬC THANG (BUSINESS RULE)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildStepRow("Bậc 1 (0-10m³)", consumption > 10 ? 10 : (consumption > 0 ? consumption : 0), BillingService.priceLevel1),
              _buildStepRow("Bậc 2 (10-20m³)", consumption > 20 ? 10 : (consumption > 10 ? consumption - 10 : 0), BillingService.priceLevel2),
              _buildStepRow("Bậc 3 (20-30m³)", consumption > 30 ? 10 : (consumption > 20 ? consumption - 20 : 0), BillingService.priceLevel3),
              _buildStepRow("Bậc 4 (>30m³)", consumption > 30 ? consumption - 30 : 0, BillingService.priceLevel4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    double baseAmount = BillingService.calculateAmount(bill.newReading - bill.oldReading) / 1.15; // Giả lập ngược để show
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildTotalRow("Cộng tiền nước", "${baseAmount.toStringAsFixed(0)} đ"),
          _buildTotalRow("Thuế VAT (5%)", "${(baseAmount * 0.05).toStringAsFixed(0)} đ"),
          _buildTotalRow("Phí BVMT (10%)", "${(baseAmount * 0.10).toStringAsFixed(0)} đ"),
          const Divider(color: Colors.white24),
          _buildTotalRow("TỔNG TIỀN THANH TOÁN", "${bill.totalAmount.toStringAsFixed(0)} đ", isHeader: true),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
            child: const Text("SỬA LẠI"),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              // Lưu hóa đơn vào SQLite (Tính năng Offline), isPaid=false vì KH chưa trả tiền
              final db = await DatabaseHelper.instance.database;
              final billMap = {...bill.toMap(), 'isPaid': 0};
              final newId = await db.insert('bills', billMap);

              // Trạng thái "đã ghi số" được tính tự động từ danh sách hóa đơn tháng hiện tại
              // (CustomerProvider.recordedCustomerCodes) — không cần cập nhật status thủ công nữa.
              
              // Reload danh sách KH trong Provider để UI cập nhật ngay lập tức
              if (context.mounted) {
                await context.read<CustomerProvider>().fetchLocal();
              }

              final savedBill = bill.copyWith(id: newId, isPaid: false);

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ReceiptScreen(customer: customer, bill: savedBill)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tạo hóa đơn thành công! Chờ khách hàng thanh toán."),
                    backgroundColor: Color(0xFF2196F3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text("TẠO HÓA ĐƠN"),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildStepRow(String label, int m3, double price) {
    if (m3 <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text("$m3 m³ x ${price.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: isHeader ? 16 : 13)),
          Text(value, style: TextStyle(color: Colors.white, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: isHeader ? 18 : 13)),
        ],
      ),
    );
  }
}
