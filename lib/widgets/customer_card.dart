import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../providers/customer_provider.dart';
import '../screens/customer/customer_detail_screen.dart';
import '../screens/customer/customer_history_screen.dart';
import '../screens/customer/receipt_screen.dart';
import '../screens/customer/route_optimization_screen.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});

  Future<void> _makeCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _sendSMS(String phone) async {
    final Uri launchUri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  Future<void> _openMap(String address) async {
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}&travelmode=driving";
    final String appleMapsUrl = "http://maps.apple.com/?daddr=${Uri.encodeComponent(address)}";
    
    final Uri googleUri = Uri.parse(googleMapsUrl);
    final Uri appleUri = Uri.parse(appleMapsUrl);

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(appleUri)) {
      await launchUrl(appleUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final isRecordedThisMonth = customerProvider.recordedCustomerCodes.contains(customer.code);

    return FutureBuilder<List<Bill>>(
      key: ValueKey('${customer.id}_${customerProvider.refreshKey}'),
      future: DatabaseHelper.instance.getBillsByCustomer(customer.id!),
      builder: (context, snapshot) {
        final bills = snapshot.data ?? [];
        final now = DateTime.now();

        // Tìm hóa đơn tháng hiện tại
        Bill? currentBill;
        try {
          currentBill = bills.firstWhere(
            (b) => b.date.month == now.month && b.date.year == now.year,
          );
        } catch (_) {
          // Chưa ghi số nước tháng này
        }

        // Tìm hóa đơn nợ của các tháng cũ (chưa thanh toán và không thuộc tháng hiện tại)
        final unpaidOldBills = bills.where((b) {
          final isCurrentMonth = b.date.month == now.month && b.date.year == now.year;
          return !b.isPaid && !isCurrentMonth;
        }).toList();

        final unpaidCount = unpaidOldBills.length;
        final unpaidAmount = unpaidOldBills.fold<double>(0.0, (sum, b) => sum + b.totalAmount);

        if (isRecordedThisMonth && currentBill != null) {
          return _buildCompletedCard(context, currentBill, unpaidCount, unpaidAmount);
        } else {
          return _buildPendingCard(context, unpaidCount, unpaidAmount);
        }
      },
    );
  }

  Widget _buildPendingCard(BuildContext context, int unpaidCount, double unpaidAmount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${customer.id}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('MÃ KH: ${customer.code}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                child: const Text('Chờ ghi số', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _openMap(customer.address),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(child: Text(customer.address, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),

          // Hiển thị cảnh báo nợ cũ nếu có
          if (unpaidCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Còn nợ $unpaidCount tháng cũ chưa trả: ${currencyFormat.format(unpaidAmount)}',
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionIcon(Icons.phone_outlined, 'Gọi điện', Colors.green, () => _makeCall(customer.phone)),
              _actionIcon(Icons.chat_bubble_outline, 'Nhắn tin', Colors.orange, () => _sendSMS(customer.phone)),
              _actionIcon(Icons.map_outlined, 'Bản đồ', Colors.blue, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteOptimizationScreen(customer: customer),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50], 
              borderRadius: BorderRadius.circular(10), 
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1))
            ),
            child: Row(
              children: [
                const Icon(Icons.speed, size: 18, color: Colors.grey),
                const SizedBox(width: 10),
                const Text('Chỉ số cũ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const Spacer(),
                Text('${customer.currentReading}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Text(' m³', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Nếu có nợ cũ: hiện 2 nút cạnh nhau; nếu không: chỉ hiện nút Ghi số nước
          Row(
            children: [
              if (unpaidCount > 0) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerHistoryScreen(customer: customer),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 16, color: Colors.red),
                      label: const Text('Thu nợ cũ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: customer))),
                    icon: const Icon(Icons.flash_on, size: 18),
                    label: const Text('Ghi số nước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, Bill currentBill, int unpaidCount, double unpaidAmount) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final amountText = currencyFormat.format(currentBill.totalAmount);
    final dateText = DateFormat('HH:mm - dd/MM/yyyy').format(currentBill.date);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${customer.id}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(customer.code, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _openMap(customer.address),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                Expanded(child: Text(customer.address, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),

          // Hiển thị cảnh báo nợ cũ nếu có
          if (unpaidCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Còn nợ $unpaidCount tháng cũ chưa trả: ${currencyFormat.format(unpaidAmount)}',
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionIcon(Icons.phone_outlined, 'Gọi điện', Colors.green, () => _makeCall(customer.phone)),
              _actionIcon(Icons.chat_bubble_outline, 'Nhắn tin', Colors.orange, () => _sendSMS(customer.phone)),
              _actionIcon(Icons.map_outlined, 'Bản đồ', Colors.blue, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteOptimizationScreen(customer: customer),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(dateText, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(amountText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Row(
                      children: [
                        Icon(
                          currentBill.isPaid ? Icons.check_circle : Icons.access_time,
                          size: 14,
                          color: currentBill.isPaid ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentBill.isPaid ? 'ĐÃ THANH TOÁN' : 'CHỜ THANH TOÁN',
                          style: TextStyle(
                            fontSize: 10,
                            color: currentBill.isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReceiptScreen(customer: customer, bill: currentBill),
                  ),
                );
              },
              icon: const Icon(Icons.print_outlined, size: 16),
              label: const Text('Xem / In hóa đơn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100],
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
