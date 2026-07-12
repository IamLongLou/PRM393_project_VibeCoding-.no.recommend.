import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _waveController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controller cho thanh tiến trình hiện giây
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_progressController)
      ..addListener(() {
        setState(() {});
      });

    // Controller cho hiệu ứng sóng nước chảy (vòng lặp vô tận)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressController.forward().then((_) => _checkAuth());
  }

  @override
  void dispose() {
    _progressController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Nền Gradient đẹp mắt
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFF2196F3)],
              ),
            ),
          ),
          
          // 2. Hiệu ứng sóng nước chảy ở dưới cùng
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: WavePainter(
                      waveValue: _waveController.value,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: WavePainter(
                      waveValue: _waveController.value + 0.5, // Lệch pha để tạo chiều sâu
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Nội dung chính
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Icon giọt nước với hiệu ứng lơ lửng
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, math.sin(_waveController.value * 2 * math.pi) * 10),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.water_drop, size: 60, color: Color(0xFF2196F3)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
                const Text(
                  'WATERBILL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hệ thống quản lý thu tiền nước',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                
                // Thanh tiến trình
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50),
                  child: SizedBox(
                    width: 280, // Giới hạn độ rộng cố định cho cả cụm
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('KHỞI TẠO HỆ THỐNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('${(_progressAnimation.value * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity, // Chạy hết độ rộng của SizedBox cha (280)
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [BoxShadow(color: Colors.white54, blurRadius: 5)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Vui lòng đợi trong giây lát...', style: TextStyle(color: Colors.white70)),
                const Spacer(flex: 2),
                const Text(
                  'PHÁT TRIỂN BỞI CÔNG TY TNHH LONG LOU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'Phiên bản 3.1.1 - © 2024 Long Hoa Cai Corp',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Vẽ hiệu ứng sóng nước chảy
class WavePainter extends CustomPainter {
  final double waveValue;
  final Color color;

  WavePainter({required this.waveValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();

    final yOffset = size.height * 0.5;
    path.moveTo(0, yOffset);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset + math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) * 20,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
