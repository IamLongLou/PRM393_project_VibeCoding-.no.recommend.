import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../providers/billing_provider.dart';
import '../../providers/customer_provider.dart';
import '../../services/billing_service.dart';
import 'receipt_screen.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatelessWidget {
  final Customer customer;
  final int newReading;
  final String imagePath;

  const PaymentScreen({super.key, required this.customer, required this.newReading, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    int consumption = newReading - customer.currentReading;
    final double total = BillingService.calculateAmount(consumption);
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Hóa Đơn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
             Text('Khách hàng: ${customer.name}'),
             Text('Chỉ số cũ: ${customer.currentReading} m³'),
             Text('Chỉ số mới: $newReading m³'),
             Text('Tiêu thụ: $consumption m³'),
             const Divider(),
             Text('Tổng cộng (gồm VAT 5% & BVMT 10%): ${format.format(total)}'),
             const SizedBox(height: 30),
             Center(child: QrImageView(data: "PAY_${customer.code}_$total", size: 200)),
             const SizedBox(height: 30),
             ElevatedButton(
               onPressed: () => _confirmPayment(context, consumption, total),
               child: const Text('Lập Hóa Đơn'),
             )
          ],
        ),
      ),
    );
  }

  void _confirmPayment(BuildContext context, int consumption, double total) async {
    final double baseAmount = total / 1.15;
    final double averageUnitPrice = consumption > 0 ? (baseAmount / consumption) : 0.0;

    final bill = Bill(
      customerId: customer.id!,
      customerName: customer.name,
      customerCode: customer.code,
      billCode: 'INV-${customer.code}-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      oldReading: customer.currentReading,
      newReading: newReading,
      consumption: consumption.toDouble(),
      unitPrice: averageUnitPrice,
      amount: baseAmount,
      vat: total - baseAmount, // stores VAT + Env Fee (15%)
      totalAmount: total,
      imagePath: imagePath,
      isSynced: false,
      isPaid: false,
    );

    final billingProvider = context.read<BillingProvider>();
    final customerProvider = context.read<CustomerProvider>();
    await billingProvider.saveBill(bill);
    await customerProvider.fetchLocal();
    if (!context.mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReceiptScreen(customer: customer, bill: bill)));
  }
}
