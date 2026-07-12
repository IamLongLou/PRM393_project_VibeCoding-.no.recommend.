import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final bool isUser = user?.role == 'user';
    final syncProvider = Provider.of<SyncProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'WaterBill',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 10),
            if (!isUser) ...[
              _buildSectionTitle('ĐỒNG BỘ DỮ LIỆU'),
              _buildSettingsGroup([
                _buildSettingItem(
                  icon: Icons.sync,
                  title: 'Trạng thái đồng bộ',
                  subtitle: syncProvider.lastSyncTime != null
                      ? 'Lần cuối: ${DateFormat('dd/MM/yyyy HH:mm').format(syncProvider.lastSyncTime!.toLocal())}'
                      : 'Chưa đồng bộ lần nào',
                  trailing: syncProvider.isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : syncProvider.unsyncedBills.isEmpty
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 22)
                          : Badge(
                              label: Text('${syncProvider.unsyncedBills.length}'),
                              child: const Icon(Icons.sync_problem, color: Colors.orange, size: 22),
                            ),
                ),
                if (syncProvider.lastError != null) ...[
                  const Divider(height: 1, indent: 60),
                  _buildSettingItem(
                    icon: Icons.error_outline,
                    title: 'Lỗi đồng bộ',
                    subtitle: syncProvider.lastError,
                    trailing: const SizedBox.shrink(),
                  ),
                ],
              ]),
            ],
            _buildSectionTitle('BẢO MẬT'),
            _buildSettingsGroup([
              _buildSettingItem(
                onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                icon: Icons.lock_outline,
                title: 'Đổi mật khẩu',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ]),
            _buildSectionTitle('VỀ ỨNG DỤNG'),
            _buildSettingsGroup([
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'Phiên bản ứng dụng',
                trailing: const Text('v2.4.0', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            ]),
            const SizedBox(height: 30),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: isUser ? 2 : 3, // Cài đặt
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (isUser) {
            if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
            if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.history);
            if (index == 2) return;
          } else {
            if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
            if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.customerList);
            if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.history);
            if (index == 3) return;
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
      ),
    );
  }

  Widget _buildProfileCard() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?.fullName ?? 'Chưa cập nhật';
    final staffId = user?.username ?? 'Chưa cập nhật';

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
              child: Icon(Icons.edit_outlined, size: 20, color: Colors.grey[600]),
            ),
          ),
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName.trim()[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const CircleAvatar(radius: 6, backgroundColor: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Staff ID: $staffId',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, bottom: 10, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF2196F3), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: trailing,
    );
  }
}
