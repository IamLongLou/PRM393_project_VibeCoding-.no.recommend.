import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import 'photo_capture_screen.dart';

class MeterReadingScreen extends StatefulWidget {
  final Customer customer;
  const MeterReadingScreen({super.key, required this.customer});

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  String _newReadingText = "";

  void _onKeyTap(String key) {
    if (key == "del") {
      if (_newReadingText.isNotEmpty) {
        setState(() => _newReadingText = _newReadingText.substring(0, _newReadingText.length - 1));
      }
    } else {
      if (_newReadingText.length < 5) {
        setState(() => _newReadingText += key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String monthYear = DateFormat('MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ghi chỉ số'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [const Icon(Icons.calendar_month, size: 16, color: Colors.grey), const SizedBox(width: 5), Text('THÁNG $monthYear', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold))]),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Row(children: [Icon(Icons.wifi, size: 12, color: Colors.blue), SizedBox(width: 4), Text('Đồng hồ nước', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold))])),
                        ],
                      ),
                    ),
                    _buildUserHeader(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _readingInputBox('CHỈ SỐ CŨ', '${widget.customer.currentReading}', isOld: true),
                          const SizedBox(width: 15),
                          _readingInputBox('CHỈ SỐ MỚI', _newReadingText.isEmpty ? "0000" : _newReadingText, isOld: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Vui lòng nhập chỉ số mới từ mặt đồng hồ khách hàng', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                    const Spacer(),
                    _buildNumericKeypad(),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        onPressed: _newReadingText.isEmpty ? null : () {
                          int newReading = int.parse(_newReadingText);
                          if (newReading < widget.customer.currentReading) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Lỗi: Chỉ số mới không được nhỏ hơn chỉ số cũ!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoCaptureScreen(customer: widget.customer, newReading: newReading)));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: _newReadingText.isEmpty ? Colors.grey[200] : Colors.blue, foregroundColor: _newReadingText.isEmpty ? Colors.grey : Colors.white),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Tiếp tục'), SizedBox(width: 10), Icon(Icons.arrow_forward, size: 18)]),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildUserHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color, 
        borderRadius: BorderRadius.circular(15), 
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1))
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.customer.id}')),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.customer.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                Text('# ${widget.customer.code}', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.qr_code_scanner, size: 20, color: Colors.blue)),
        ],
      ),
    );
  }

  Widget _readingInputBox(String label, String value, {required bool isOld}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isOld ? Colors.grey : Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isOld 
                  ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100]) 
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isOld ? Colors.transparent : Colors.blue, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isOld ? (isDark ? Colors.white60 : Colors.grey[600]) : (isDark ? Colors.white : Colors.black87))),
                const SizedBox(width: 4),
                Text('m³', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          _keyRow(["1", "2", "3"]),
          _keyRow(["4", "5", "6"]),
          _keyRow(["7", "8", "9"]),
          _keyRow([".", "0", "del"]),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys) => Row(
    children: keys.map((k) => Expanded(child: _keyButton(k))).toList(),
  );

  Widget _keyButton(String k) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (k == ".") return const Center(child: CircleAvatar(radius: 3, backgroundColor: Colors.grey));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onKeyTap(k),
        child: Container(
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white, 
            borderRadius: BorderRadius.circular(12), 
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)]
          ),
          child: k == "del" 
              ? const Icon(Icons.backspace_outlined, color: Colors.redAccent, size: 20)
              : Text(k, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ),
      ),
    );
  }
}
