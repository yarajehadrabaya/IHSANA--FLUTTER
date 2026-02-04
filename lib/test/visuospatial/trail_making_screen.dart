import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../theme/app_theme.dart';
import '../../models/point_model.dart';
import '../../utils/resampler.dart';
import '../../painters/drawing_painter.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../utils/audio_session.dart';
import '../widgets/test_question_scaffold.dart';
import 'cube_copy_screen.dart';

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

    // 🔊 اربط الـ player مع AudioSession
    AudioSession.register(_audioPlayer);

    _playInstruction();
  }

  // ✅ الإضافة الوحيدة: إيقاف الصوت فور مغادرة الصفحة
  @override
  void deactivate() {
    _audioPlayer.stop();
    super.deactivate();
  }

  @override
  void dispose() {
    AudioSession.unregister(_audioPlayer);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    await AudioSession.play(
      _audioPlayer,
      AssetSource('audio/tmt.mp3'),
    );
  }

  Future<void> _loadImage() async {
    final data = await DefaultAssetBundle.of(context)
        .load('assets/images/trail_making.png');
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

  Future<void> _submitAndAnalyze(Size canvasSize) async {
    if (points.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final resampled = resample(points, 0.05);

      final data = {
        "canvasWidth": canvasSize.width,
        "canvasHeight": canvasSize.height,
        "points": resampled.map((e) => e.toJson()).toList(),
      };

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/tmt_data.json');
      await tempFile.writeAsString(jsonEncode(data));

      final result = await _apiService.checkTrails(tempFile.path);
      TestSession.trailsScore = (result['score'] as int? ?? 0);
      debugPrint("Score from API: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");

      if (mounted) {
        TestSession.nextQuestion();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CubeCopyScreen()),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في التحليل')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================== CANVAS ==================
  Widget _trailContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize =
            Size(constraints.maxWidth, constraints.maxHeight);

        if (bgImage == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.cardDecoration,
          child: Stack(
            children: [
              GestureDetector(
                onPanStart: (d) =>
                    _startDraw(d.localPosition, canvasSize),
                onPanUpdate: (d) =>
                    _addPoint(d.localPosition, canvasSize),
                child: CustomPaint(
                  size: canvasSize,
                  painter: DrawingPainter(points, bgImage!),
                ),
              ),

              // ===== زر إعادة الرسم =====
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: AppTheme.primary.withOpacity(0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      setState(() {
                        points.clear();
                        startTime = null;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.refresh,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'تتبّع المسار',
          instruction:
              'اربط الأرقام والحروف بالتناوب (1-أ-2-ب...) دون رفع إصبعك عن الشاشة',

          // 🔒 الصوت ليس إجباري هنا (لم يُمس)
          allowMute: true,

          content: _trailContent(),

          isNextEnabled: points.isNotEmpty && !_isLoading,

        onNext: () {
          _audioPlayer.stop(); // 🔇 أوقف الصوت فورًا
          final RenderBox box =
              context.findRenderObject() as RenderBox;
          _submitAndAnalyze(box.size);
        },

          onEndSession: () {
            Navigator.popUntil(context, (r) => r.isFirst);
          },
        ),

        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}