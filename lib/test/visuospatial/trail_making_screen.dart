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
    _playInstruction();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      await _audioPlayer.play(AssetSource('audio/tmt.mp3'));
    } catch (_) {}
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

      if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'تتبّع المسار',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),

                  TextButton.icon(
                    onPressed: () => Navigator.popUntil(
                        context, (r) => r.isFirst),
                    icon: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'إنهاء الجلسة',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'اربط الأرقام والحروف بالتناوب (1-أ-2-ب...) دون رفع إصبعك عن الشاشة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.cardDecoration,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final canvasSize = Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );

                          if (bgImage == null) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

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
                  ),

                  const SizedBox(height: 20),

                  // ===== أزرار موحّدة 100% =====
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              points.clear();
                              startTime = null;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text(
                            'إعادة الرسم',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: points.isEmpty || _isLoading
                              ? null
                              : () {
                                  final RenderBox box =
                                      context.findRenderObject() as RenderBox;
                                  _submitAndAnalyze(box.size);
                                },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'إنهاء وتحليل',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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
