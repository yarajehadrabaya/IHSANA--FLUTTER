import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart'; // لتشغيل التعليمات
import '../../theme/app_theme.dart';
import '../../models/point_model.dart';
import '../../utils/resampler.dart';
import '../../painters/drawing_painter.dart';
import '../../utils/moca_api_service.dart'; // للاتصال بالـ API
import '../../utils/test_session.dart'; // لحفظ السكور
import 'cube_copy_screen.dart'; // الانتقال للمكعب

class TrailMakingScreen extends StatefulWidget {
  const TrailMakingScreen({super.key});

  @override
  State<TrailMakingScreen> createState() => _TrailMakingScreenState();
}

class _TrailMakingScreenState extends State<TrailMakingScreen> {
  List<DrawPoint> points = [];
  DateTime? startTime;
  ui.Image? bgImage;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _playInstruction(); // ✅ تشغيل صوت tmt.mp3 فوراً عند فتح الشاشة
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // 🔊 وظيفة تشغيل فويس التعليمات
  Future<void> _playInstruction() async {
    try {
      // تم تصحيح المسار ليتوافق مع مكتبة audioplayers (بدون assets/)
      await _audioPlayer.play(AssetSource('audio/tmt.mp3'));
    } catch (e) {
      debugPrint("Error playing TMT instruction: $e");
    }
  }

  Future<void> _loadImage() async {
    // تحميل صورة النقاط الخلفية (1-أ-2-ب...)
    final data = await DefaultAssetBundle.of(
      context,
    ).load('assets/images/trail_making.png');
    final img = await decodeImageFromList(data.buffer.asUint8List());
    setState(() => bgImage = img);
  }

  void _startDraw(Offset pos, Size size) {
    startTime ??= DateTime.now();
    _addPoint(pos, size);
  }

  void _addPoint(Offset pos, Size size) {
    if (startTime == null) return;
    final t = DateTime.now().difference(startTime!).inMilliseconds / 1000.0;

    // ✅ النقطة الذهبية: نحسب النسب المئوية (nx, ny) لكي يعمل الكود على أي موبايل
    points.add(
      DrawPoint(
        x: pos.dx,
        y: pos.dy,
        nx: pos.dx / size.width,
        ny: pos.dy / size.height,
        t: t,
      ),
    );
    setState(() {});
  }

  // 🚀 دالة الإرسال والتحليل والانتقال
  Future<void> _submitAndAnalyze(Size canvasSize) async {
    if (points.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. إعادة عينة النقاط لتقليل حجم البيانات المرسلة
      final resampled = resample(points, 0.05);

      // 2. تجهيز بيانات الـ JSON
      final data = {
        "canvasWidth": canvasSize.width,
        "canvasHeight": canvasSize.height,
        "points": resampled.map((e) => e.toJson()).toList(),
      };

      // 3. إنشاء ملف مؤقت للإرسال
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tmt_data.json');
      await tempFile.writeAsString(jsonEncode(data));

      // 4. استدعاء الـ API المجمع في ملف السيرفس
      final result = await _apiService.checkTrails(tempFile.path);

      // -----------------------------------------------------------
      // >>> [DEBUG] طباعة النتيجة في الكونسول للفحص <<<
      debugPrint("====================================");
      debugPrint("📊 [TMT TEST RESULT]");
      debugPrint("Score from API: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("====================================");
      // -----------------------------------------------------------

      // ✅ حفظ النتيجة في الخزنة (نقطة واحدة)
      TestSession.trailsScore = (result['score'] as int? ?? 0);

      if (mounted) {
        // ✅ الانتقال التلقائي لشاشة رسم المكعب
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CubeCopyScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error in TMT submission: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("خطأ في التحليل: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('تتبّع المسار'),
            automaticallyImplyLeading: false, // منع الرجوع للخلف
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text(
                  'إنهاء الجلسة',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اربط الأرقام والحروف بالتناوب (1-أ-2-ب...) دون رفع إصبعك عن الشاشة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    if (bgImage == null)
                      return const Center(child: CircularProgressIndicator());

                    return GestureDetector(
                      onPanStart: (d) =>
                          _startDraw(d.localPosition, canvasSize),
                      onPanUpdate: (d) =>
                          _addPoint(d.localPosition, canvasSize),
                      child: CustomPaint(
                        size: canvasSize,
                        painter: DrawingPainter(points, bgImage!),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // زر مسح الرسم للبدء من جديد
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          points.clear();
                          startTime = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة الرسم'),
                    ),
                    const SizedBox(width: 16),
                    // الزر الأساسي الذي يقوم بكل العمليات
                    ElevatedButton.icon(
                      onPressed: points.isEmpty || _isLoading
                          ? null
                          : () {
                              final RenderBox box =
                                  context.findRenderObject() as RenderBox;
                              _submitAndAnalyze(box.size);
                            },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('إنهاء وتحليل'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // شاشة لودينج شفافة تظهر أثناء التحليل
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "جاري تحليل مسار الرسم...",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
