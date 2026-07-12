import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final userName = user?.fullName ?? 'Nhân viên';
    final userRole = (user?.role == 'STAFF' ? 'Nhân viên thu tiền' : 'Khách hàng');

    final customerProvider = context.watch<CustomerProvider>();
    final all = customerProvider.allCustomers;
    final completedTasks = all.where((c) => customerProvider.recordedCustomerCodes.contains(c.code)).length;
    final pendingTasks = all.isEmpty && customerProvider.isLoading ? 0 : all.length - completedTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Layout
              Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: Color(0xFF5D9CEC),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userRole, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Tóm tắt trạng thái Offline
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5D9CEC), Color(0xFF4FC1E9)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 40),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Chế độ ngoại tuyến", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("Có $pendingTasks công việc chưa hoàn thành", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text("Menu Nghiệp vụ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),

              // Grid Menu điều hướng
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _menuItem(Icons.people_alt_rounded, "Khách hàng", const Color(0xFF48CFAD), () => onNavigate(0)),
                  _menuItem(Icons.sync_rounded, "Đồng bộ", const Color(0xFFAC92EC), () => Navigator.pushNamed(context, "/sync")),
                  _menuItem(Icons.pie_chart_rounded, "Thống kê", const Color(0xFF5D9CEC), () => onNavigate(1)),
                  _menuItem(Icons.account_circle_rounded, "Hồ sơ", const Color(0xFFFC6E51), () => onNavigate(2)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
