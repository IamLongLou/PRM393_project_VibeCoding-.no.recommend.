import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import 'payment_screen.dart';

class PhotoCaptureScreen extends StatefulWidget {
  final Customer customer;
  final int newReading;
  const PhotoCaptureScreen({super.key, required this.customer, required this.newReading});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  XFile? _capturedImage;
  final _picker = ImagePicker();

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image != null) {
        setState(() => _capturedImage = image);
      }
    } catch (e) {
      // Camera unavailable (e.g. on simulator/web) – fallback to gallery
      _pickFromGallery();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image != null) {
      setState(() => _capturedImage = image);
    }
  }

  Widget _buildImagePreview() {
    if (_capturedImage != null) {
      if (kIsWeb) {
        return Image.network(_capturedImage!.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(_capturedImage!.path), fit: BoxFit.cover);
      }
    }
    // Placeholder when no photo taken yet
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          color: Colors.grey[900],
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 64),
              SizedBox(height: 16),
              Text('Nhấn nút chụp ảnh để chụp đồng hồ nước',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        // Corner frame guides
        Positioned(top: 50, left: 50, child: _cornerFrame(top: true, left: true)),
        Positioned(top: 50, right: 50, child: _cornerFrame(top: true, left: false)),
        Positioned(bottom: 50, left: 50, child: _cornerFrame(top: false, left: true)),
        Positioned(bottom: 50, right: 50, child: _cornerFrame(top: false, left: false)),
        Positioned(
          bottom: 70,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              Icon(Icons.center_focus_weak, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Căn chỉnh đồng hồ vào khung', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _cornerFrame({required bool top, required bool left}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
          bottom: !top ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
          left: left ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
          right: !left ? const BorderSide(color: Colors.blue, width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('d/M/yyyy - HH:mm').format(now);
    final tempBillCode = 'TMP-${widget.customer.code}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  const Text('Chụp ảnh công tơ', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_capturedImage == null)
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined, color: Colors.white70),
                      tooltip: 'Chọn ảnh từ thư viện',
                      onPressed: _pickFromGallery,
                    ),
                ],
              ),
            ),
            // Customer address & timestamp
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.location_on, color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          Expanded(child: Text(widget.customer.address, style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                        Row(children: [
                          const Icon(Icons.access_time, color: Colors.blue, size: 14),
                          const SizedBox(width: 4),
                          Text(dateStr, style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(5)),
                    child: Text(tempBillCode, style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Camera viewfinder / captured image
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 20),
            // Reading indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.info_outline, color: Colors.blue),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHỈ SỐ VỪA NHẬP', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${widget.newReading.toString().padLeft(5, '0')} m³', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_capturedImage == null ? 'Chụp ảnh' : 'Chụp lại'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final imagePath = _capturedImage?.path ?? '';
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            customer: widget.customer,
                            newReading: widget.newReading,
                            imagePath: imagePath,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Xác nhận & Lưu'),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Ảnh chụp sẽ được lưu cục bộ và đính kèm vào hóa đơn khi đồng bộ.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 9),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
