import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/customer_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});
  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<SyncProvider>().fetchUnsyncedBills();
      }
    });
  }

  Future<void> _doSync() async {
    final syncProvider = context.read<SyncProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final success = await syncProvider.syncAll(customerProvider);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đồng bộ thành công! Danh sách khách hàng đã được cập nhật.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${syncProvider.lastError ?? "Đồng bộ thất bại"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();
    final bills = syncProvider.unsyncedBills;

    return Scaffold(
      appBar: AppBar(title: const Text('Đồng bộ dữ liệu')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Text('Có ${bills.length} hóa đơn chờ đồng bộ.'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: bills.length,
              itemBuilder: (context, i) => ListTile(
                title: Text('HĐ: ${bills[i].billCode}'),
                subtitle: Text('KH: ${bills[i].customerName}'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: syncProvider.isSyncing || bills.isEmpty ? null : _doSync,
              child: Text(syncProvider.isSyncing ? 'Đang gửi...' : 'Đồng bộ ngay'),
            ),
          )
        ],
      ),
    );
  }
}
