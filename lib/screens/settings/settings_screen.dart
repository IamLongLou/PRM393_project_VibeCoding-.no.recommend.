import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../routes/app_routes.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoSync = true;
  bool _biometric = false;

  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text('Trung tâm hỗ trợ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildHelpItem(Icons.question_answer_outlined, 'Hướng dẫn sử dụng máy in Bluetooth'),
                    _buildHelpItem(Icons.sync_problem, 'Lỗi không đồng bộ được dữ liệu'),
                    _buildHelpItem(Icons.history_edu, 'Cách tra cứu lịch sử thu tiền'),
                    _buildHelpItem(Icons.phone_in_talk_outlined, 'Gọi hotline kỹ thuật: 1900 1234'),
                    const Divider(height: 40),
                    const Text('Các câu hỏi thường gặp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    const Text('1. Tôi phải làm gì nếu app bị treo khi đang thu tiền?'),
                    const Text('Hãy thử xóa bộ nhớ đệm trong phần cài đặt hoặc khởi động lại ứng dụng.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title) => ListTile(
    leading: Icon(icon, color: Colors.blue),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    trailing: const Icon(Icons.chevron_right, size: 18),
    onTap: () {},
  );

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
            _buildSectionTitle('DEVICE & DATA'),
            _buildSettingsGroup([
              _buildSettingItem(
                icon: Icons.brightness_4_outlined,
                title: 'Dark Mode',
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) => themeProvider.toggleTheme(v),
                  activeThumbColor: Colors.blue,
                ),
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                icon: Icons.print_outlined,
                title: 'Thermal Printer',
                trailing: const Text(
                  'Disconnected',
                  style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                icon: Icons.sync,
                title: 'Auto-Sync',
                trailing: Switch(
                  value: _autoSync,
                  onChanged: (v) => setState(() => _autoSync = v),
                  activeThumbColor: Colors.blue,
                ),
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                icon: Icons.delete_outline,
                title: 'Clear Cache',
                subtitle: 'Current usage: 24.5 MB',
                trailing: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bộ nhớ đệm!')));
                  },
                  child: const Text('CLEAR', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            _buildSectionTitle('SECURITY'),
            _buildSettingsGroup([
              _buildSettingItem(
                onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                icon: Icons.lock_outline,
                title: 'Change Password',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                trailing: Switch(
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                  activeThumbColor: Colors.blue,
                ),
              ),
            ]),
            _buildSectionTitle('SUPPORT'),
            _buildSettingsGroup([
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'App Version',
                trailing: const Text('v2.4.0', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              const Divider(height: 1, indent: 60),
              _buildSettingItem(
                onTap: _showHelpCenter,
                icon: Icons.help_outline,
                title: 'Help Center',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 30),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
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
        currentIndex: 3, // Cài đặt
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, AppRoutes.home);
          if (index == 1) Navigator.pushReplacementNamed(context, AppRoutes.customerList);
          if (index == 2) Navigator.pushReplacementNamed(context, AppRoutes.history);
          if (index == 3) return;
        },
        items: const [
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
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=random'),
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
