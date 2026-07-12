import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../services/database_helper.dart';
import 'package:intl/intl.dart';

class ReceiptScreen extends StatefulWidget {
  final Customer customer;
  final Bill bill;
  const ReceiptScreen({super.key, required this.customer, required this.bill});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  late bool _isPaid;
  List<Bill> _unpaidOldBills = [];
  double _totalOldDebt = 0.0;
  bool _isLoadingOldBills = true;

  @override
  void initState() {
    super.initState();
    _isPaid = widget.bill.isPaid;
    _loadUnpaidOldBills();
  }

  Future<void> _loadUnpaidOldBills() async {
    try {
      final bills = await DatabaseHelper.instance.getBillsByCustomer(widget.customer.id!);
      final unpaid = bills.where((b) {
        // Lấy hóa đơn chưa thanh toán và khác hóa đơn hiện tại đang xem
        return !b.isPaid && b.id != widget.bill.id;
      }).toList();

      if (mounted) {
        setState(() {
          _unpaidOldBills = unpaid;
          _totalOldDebt = unpaid.fold(0.0, (sum, b) => sum + b.totalAmount);
          _isLoadingOldBills = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading unpaid bills: $e');
      if (mounted) {
        setState(() => _isLoadingOldBills = false);
      }
    }
  }

  Future<void> _shareReceipt() async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/receipt_${widget.bill.billCode}.png').create();
        await imagePath.writeAsBytes(imageBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(imagePath.path)],
            text: 'Biên lai tiền nước - ${widget.customer.name} - ${widget.bill.billCode}',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi chia sẻ biên lai')),
        );
      }
    }
  }

  Future<void> _printReceipt() async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 100),
        pixelRatio: 2.0,
      );

      if (imageBytes != null) {
        await Printing.layoutPdf(
          onLayout: (format) async => imageBytes,
          name: 'Biên lai ${widget.bill.billCode}',
        );
      }
    } catch (e) {
      debugPrint('Error printing receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi in biên lai')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Hóa đơn tiền nước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: Icon(Icons.print_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: _printReceipt,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Header trạng thái động
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _isPaid
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _isPaid ? Icons.check_circle : Icons.hourglass_top,
                    color: _isPaid ? Colors.green : Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isPaid ? 'Đã nhận thanh toán ✓' : 'Hóa đơn đã tạo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isPaid ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPaid
                        ? 'Khách hàng đã thanh toán thành công'
                        : 'Chờ khách hàng thanh toán tiền mặt',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hiển thị cảnh báo nợ cũ và hỗ trợ thanh toán hàng loạt
            if (!_isLoadingOldBills && _unpaidOldBills.isNotEmpty) ..._buildOldBillsWarning(format, isDark),

            // Nút xác nhận thanh toán kỳ hiện tại (chỉ hiện khi chưa thanh toán kỳ này)
            if (!_isPaid) ..._buildPaymentConfirmButton(format),

            Screenshot(
              controller: _screenshotController,
              child: _buildMainReceipt(format, isDark),
            ),
            const SizedBox(height: 20),
            // Nút về màn hình chính
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Về màn hình chính', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text('bản quyền thuộc về WaterBill © 2024', style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Khối UI hiển thị dư nợ cũ và nút thu toàn bộ
  List<Widget> _buildOldBillsWarning(NumberFormat format, bool isDark) {
    // Dùng _isPaid (state local) thay vì widget.bill.isPaid (immutable)
    final double totalCollect = _isPaid ? _totalOldDebt : (_totalOldDebt + widget.bill.totalAmount);
    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'PHÁT HIỆN NỢ CŨ (${_unpaidOldBills.length} THÁNG)',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Khách hàng vẫn còn nợ các hóa đơn kỳ trước:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Danh sách các hóa đơn nợ
            ..._unpaidOldBills.map((b) {
              final dateStr = DateFormat('MM/yyyy').format(b.date);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('• Kỳ hóa đơn tháng $dateStr', style: const TextStyle(fontSize: 13)),
                    Text(
                      format.format(b.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 20, color: Colors.grey, thickness: 0.1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng nợ cũ chưa trả:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  format.format(_totalOldDebt),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Nút gom toàn bộ nợ
            ElevatedButton.icon(
              onPressed: () async {
                final syncProvider = context.read<SyncProvider>();
                final customerProvider = context.read<CustomerProvider>();
                
                // 1. Cập nhật hóa đơn hiện tại nếu chưa thanh toán
                if (!_isPaid && widget.bill.id != null) {
                  await DatabaseHelper.instance.markBillAsPaid(widget.bill.id!);
                }
                
                // 2. Cập nhật tất cả các hóa đơn nợ cũ của khách hàng
                await DatabaseHelper.instance.markAllBillsAsPaidForCustomer(widget.customer.id!);
                
                // 3. Đồng bộ các Provider để giao diện thay đổi tức thì
                await syncProvider.fetchUnsyncedBills();
                await customerProvider.fetchLocal();

                if (mounted) {
                  setState(() {
                    _isPaid = true;
                    _unpaidOldBills = [];
                    _totalOldDebt = 0.0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ Đã thu thành công toàn bộ dư nợ ${format.format(totalCollect)} của khách hàng ${widget.customer.name}',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                'THU TOÀN BỘ DƯ NỢ (${format.format(totalCollect)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Nút xác nhận đã nhận tiền mặt từ khách hàng cho kỳ hiện tại
  List<Widget> _buildPaymentConfirmButton(NumberFormat format) {
    return [
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        child: ElevatedButton.icon(
          onPressed: () async {
            final syncProvider = context.read<SyncProvider>();
            final customerProvider = context.read<CustomerProvider>();
            final billId = widget.bill.id;
            if (billId != null) {
              await DatabaseHelper.instance.markBillAsPaid(billId);
              await syncProvider.fetchUnsyncedBills();
              await customerProvider.fetchLocal();
            }
            if (mounted) {
              setState(() => _isPaid = true);
              // Reload lại danh sách nợ cũ: hóa đơn vừa trả sẽ biến khỏi danh sách
              await _loadUnpaidOldBills();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Xác nhận khách hàng ${widget.customer.name} đã thanh toán ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.bill.totalAmount)}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.payments_outlined, size: 22),
          label: const Text(
            'XÁC NHẬN ĐÃ NHẬN TIỀN',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ];
  }

  Widget _buildMainReceipt(NumberFormat format, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.water_drop, color: isDark ? Colors.white : Colors.black, size: 24),
                    const SizedBox(width: 8),
                    const Text('WaterBill', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('MÃ HÓA ĐƠN', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(widget.bill.billCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(height: 1, color: Colors.grey, thickness: 0.1)),
                
                _infoItem(Icons.person_outline, 'Khách hàng', widget.customer.name, 'ID: ${widget.customer.code}', isDark),
                const SizedBox(height: 20),
                _infoItem(Icons.location_on_outlined, 'Địa chỉ', widget.customer.address, null, isDark),
                const SizedBox(height: 20),
                _infoItem(Icons.calendar_today_outlined, 'Thời gian', DateFormat('dd/MM/yyyy HH:mm').format(widget.bill.date), null, isDark),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider(height: 1, color: Colors.grey, thickness: 0.1)),
                
                _billDetail('Chỉ số cũ', '${widget.bill.oldReading} m³', isDark),
                _billDetail('Chỉ số mới', '${widget.bill.newReading} m³', isDark),
                _billDetail('Tiêu thụ', '${widget.bill.consumption.toInt()} m³', isDark, isBlue: true),
                _billDetail('Đơn giá', 'Bậc thang (5.973 – 15.929 đ/m³)', isDark),
                _billDetail('Thuế VAT (5%) + BVMT (10%)', format.format(widget.bill.vat), isDark),
                
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG TIỀN', style: TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(format.format(widget.bill.totalAmount), style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.bold, fontSize: 22)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value, String? extra, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              if (extra != null) ...[
                const SizedBox(height: 2),
                Text(extra, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _billDetail(String label, String value, bool isDark, {bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isBlue ? const Color(0xFF2196F3) : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
