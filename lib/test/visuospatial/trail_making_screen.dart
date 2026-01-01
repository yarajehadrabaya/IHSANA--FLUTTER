import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TrailMakingScreen extends StatefulWidget {
  const TrailMakingScreen({super.key});

  @override
  State<TrailMakingScreen> createState() => _TrailMakingScreenState();
}

class _TrailMakingScreenState extends State<TrailMakingScreen> {
  final List<Offset?> _points = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('تتبّع المسار'),
        actions: [
          TextButton(
            onPressed: () {
              // إنهاء الجلسة
              Navigator.pop(context);
            },
            child: const Text(
              'إنهاء الجلسة',
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'اربط الأرقام والحروف بالتناوب دون رفع إصبعك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _points.add(details.localPosition);
                });
              },
              onPanEnd: (_) {
                _points.add(null);
              },
              child: CustomPaint(
                painter: _TrailPainter(_points),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/trail_making_a.png',
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                // الانتقال للسؤال التالي
              },
              child: const Text('متابعة'),
            ),
          )
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset?> points;

  _TrailPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
