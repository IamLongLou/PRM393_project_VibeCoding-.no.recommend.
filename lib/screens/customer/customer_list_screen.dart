import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/billing_provider.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../widgets/customer_card.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatter_utils.dart';

class CustomerListScreen extends StatefulWidget {
  final int initialTabIndex;
  const CustomerListScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this, 
      initialIndex: widget.initialTabIndex
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchAndFilter(),
            _buildTabSwitcher(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTab(),
                  _buildCompletedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String title = _tabController.index == 0 ? 'Chưa ghi số' : 'Lịch sử ghi nước';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF00BCD4)],
              ),
              borderRadius: BorderRadius.circular(8)
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => Provider.of<CustomerProvider>(context, listen: false).searchCustomers(value),
              decoration: InputDecoration(
                hintText: 'Tìm tên hoặc mã KH...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Theme.of(context).cardTheme.color,
                filled: true,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.tune, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        tabs: const [Tab(text: 'Chưa ghi số'), Tab(text: 'Đã ghi số')],
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildPendingTab() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = provider.customers.where((c) => !provider.recordedCustomerCodes.contains(c.code)).toList();
        return _buildListView(list, isPending: true);
      },
    );
  }

  Widget _buildCompletedTab() {
    return Consumer2<CustomerProvider, BillingProvider>(
      builder: (context, custProv, billProv, _) {
        if (custProv.isLoading && custProv.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = custProv.customers.where((c) => custProv.recordedCustomerCodes.contains(c.code)).toList();
        return FutureBuilder<List<Bill>>(
          future: Provider.of<BillingProvider>(context, listen: false).getAllBills(),
          builder: (context, snapshot) {
            double totalToday = 0;
            if (snapshot.hasData) {
              final List<Bill> bills = snapshot.data!;
              final today = DateTime.now();
              totalToday = bills
                .where((b) => b.date.day == today.day && b.date.month == today.month)
                .fold(0.0, (sum, b) => sum + b.totalAmount);
            }
            return Column(
              children: [
                _buildSummaryBanner(totalToday),
                Expanded(child: _buildListView(list, isPending: false)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryBanner(double total) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03), 
        borderRadius: BorderRadius.circular(15)
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
          const SizedBox(width: 12),
          const Expanded(child: Text('TỔNG THU TRONG NGÀY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Text(FormatterUtils.formatCurrency(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildListView(List<Customer> list, {required bool isPending}) {
    if (list.isEmpty) return const Center(child: Text('Trống'));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == list.length) return _buildFooter();
        return CustomerCard(customer: list[index]);
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.water_drop_outlined, color: Colors.grey.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: 8),
          Text('${AppStrings.companyName}\n${AppStrings.groupName}', 
            textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.grey, fontSize: 10)
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 1,
      selectedItemColor: Colors.blue,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Khách hàng'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Cài đặt'),
      ],
      onTap: (i) {
        if (i == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
        if (i == 2) Navigator.pushReplacementNamed(context, AppRoutes.history);
        if (i == 3) Navigator.pushReplacementNamed(context, AppRoutes.settings);
      },
    );
  }
}
