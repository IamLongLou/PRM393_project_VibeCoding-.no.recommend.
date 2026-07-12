import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../providers/customer_provider.dart';
import '../../services/database_helper.dart';
import '../../services/api_service.dart';
import '../../models/customer.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _initialReadingController = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _initialReadingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final db = DatabaseHelper.instance;
      final dbInstance = await db.database;
      final code = _codeController.text.trim().toUpperCase();
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();
      final phone = _phoneController.text.trim();
      final reading = int.tryParse(_initialReadingController.text.trim()) ?? 0;

      // Kiểm tra mã KH đã tồn tại chưa
      final existing = await dbInstance.query(
        'customers',
        where: 'code = ?',
        whereArgs: [code],
      );
      if (existing.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Mã khách hàng đã tồn tại. Vui lòng dùng mã khác.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isSaving = false);
        return;
      }

      // 1. Thử gọi API server trước
      final serverId = await ApiService.createCustomer(
        code: code, name: name, address: address,
        phone: phone, currentReading: reading,
      );

      // 2. Lưu vào SQLite local (dùng ID từ server nếu có)
      final newCustomer = Customer(
        id: serverId,
        code: code,
        name: name,
        address: address,
        phone: phone,
        currentReading: reading,
      );
      await dbInstance.insert(
        'customers',
        newCustomer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Reload danh sách
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final nav = Navigator.of(context);
        await context.read<CustomerProvider>().fetchLocal();
        final syncNote = serverId != null ? '' : ' (lưu cục bộ, chưa có mạng)';
        messenger.showSnackBar(
          SnackBar(
            content: Text('✅ Đã thêm khách hàng $name ($code) thành công!$syncNote'),
            backgroundColor: Colors.green,
          ),
        );
        nav.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi thêm khách hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Thêm khách hàng mới',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header icon
              Center(
                child: Container(
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
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 38),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Điền thông tin khách hàng mới',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              const SizedBox(height: 28),

              _buildField(
                label: 'Mã khách hàng *',
                controller: _codeController,
                hint: 'VD: KH010',
                icon: Icons.badge_outlined,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mã khách hàng';
                  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(v.trim())) return 'Chỉ được dùng chữ cái và số';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Họ và tên *',
                controller: _nameController,
                hint: 'VD: Nguyễn Văn A',
                icon: Icons.person_outline,
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên khách hàng' : null,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Địa chỉ *',
                controller: _addressController,
                hint: 'VD: 123 Đường ABC, Hà Nội',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Số điện thoại *',
                controller: _phoneController,
                hint: 'VD: 0912345678',
                icon: Icons.phone_outlined,
                isDark: isDark,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (!RegExp(r'^0\d{9}$').hasMatch(v.trim())) return 'Số điện thoại không hợp lệ (10 chữ số, bắt đầu bằng 0)';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildField(
                label: 'Chỉ số đồng hồ ban đầu (m³)',
                controller: _initialReadingController,
                hint: '0',
                icon: Icons.speed_outlined,
                isDark: isDark,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 0) return 'Chỉ số phải là số nguyên không âm';
                  return null;
                },
              ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Khách hàng mới sẽ được đồng bộ trực tiếp lên server và lưu cục bộ.',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: Text(
                    _isSaving ? 'Đang lưu...' : 'Thêm khách hàng',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: Colors.blue, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
