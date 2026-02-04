import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import 'package:ihsana/test/naming/naming_intro_screen.dart';
import 'package:ihsana/test/naming/naming_lion_screen.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';

class ClockDrawingScreen extends StatefulWidget {
  const ClockDrawingScreen({super.key});

  @override
  State<ClockDrawingScreen> createState() => _ClockDrawingScreenState();
}

class _ClockDrawingScreenState extends State<ClockDrawingScreen> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _actionAudioPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();

  Uint8List? _imageBytes;
  String? _imagePath;

  bool _isLoading = false;
  bool _captured = false;
  bool _showStream = true;

  WebViewController? _webController;

  @override
  void initState() {
    super.initState();
    _playInstruction();
    _initWebView();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('${SessionContext.raspberryBaseUrl}/video-stream'),
      );
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _actionAudioPlayer.dispose();
    super.dispose();
  }

  // ================= 🔊 INSTRUCTION =================
  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(
        AssetSource('audio/clock.mp3'),
      );
    } catch (_) {}
  }

  // ================= 📱 MOBILE =================
  Future<void> _captureImageMobile() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
      _captured = true;
      _showStream = false;
    });
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _captureImageHardware() async {
    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/capture-image'),
      );

      if (res.statusCode != 200) {
        throw Exception('Capture failed');
      }

      final dir = await Directory.systemTemp.createTemp();
      final path = '${dir.path}/clock.jpg';
      final file = File(path);
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _imagePath = path;
        _imageBytes = res.bodyBytes;
        _captured = true;
        _showStream = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التقاط الصورة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🔄 RESET =================
  void _resetCapture() {
    _initWebView();
    setState(() {
      _imageBytes = null;
      _imagePath = null;
      _captured = false;
      _showStream = true;
    });
  }

  // ================= 🚀 ANALYZE =================
  Future<void> _submitAndAnalyze() async {
    if (_imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await _apiService.checkVision(_imagePath!, 'clock');

      TestSession.clockScore = result['score'] ?? 0;

      debugPrint('🧠 CLOCK SCORE: ${TestSession.clockScore}');
      debugPrint('🧠 FULL RESULT: $result');

      if (!mounted) return;
      TestSession.nextQuestion();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NamingLionScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== أصوات الأزرار (كما هي) =====
  Future<void> _playCaptureVoice() async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(
        AssetSource('audio/capture_photo.mp3'),
      );
    } catch (_) {}
  }

  Future<void> _stopCaptureVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playRetakeVoice() async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(
        AssetSource('audio/retake_photo.mp3'),
      );
    } catch (_) {}
  }

  Future<void> _stopRetakeVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  // ================= 🧱 UI (كما هو) =================
  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        SessionContext.testMode == TestMode.mobile;
    final bool isHardware =
        SessionContext.testMode == TestMode.hardware;

    return TestQuestionScaffold(
      title: 'رسم الساعة',
      instruction: isMobile
          ? 'ارسم ساعة كاملة بالأرقام والعقارب (11:10) ثم صوّرها بالجوال.'
          : 'ارسم الساعة على الورقة أمام الجهاز ثم اضغط التقاط.',
      onRepeatInstruction: _playInstruction,
      content: Column(
        children: [
          const SizedBox(height: 12),

          Expanded(
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.45),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_captured && _imageBytes != null)
                        Image.memory(_imageBytes!, fit: BoxFit.cover)
                      else if (!_captured &&
                          isHardware &&
                          _showStream &&
                          _webController != null)
                        WebViewWidget(controller: _webController!)
                      else
                        Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Text(
                            'بانتظار التقاط الصورة...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),

                      if (!_captured)
                        Center(
                          child: GestureDetector(
                            onTapDown: (_) => _playCaptureVoice(),
                            onTapUp: (_) => _stopCaptureVoice(),
                            onTapCancel: _stopCaptureVoice,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt),
                              label: Text(
                                isMobile
                                    ? 'التقاط بالجوال'
                                    : 'التقاط من الجهاز',
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : (isMobile
                                      ? _captureImageMobile
                                      : _captureImageHardware),
                            ),
                          ),
                        ),

                      if (_captured)
                        Center(
                          child: GestureDetector(
                            onTapDown: (_) => _playRetakeVoice(),
                            onTapUp: (_) => _stopRetakeVoice(),
                            onTapCancel: _stopRetakeVoice,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('إعادة الالتقاط'),
                              onPressed:
                                  _isLoading ? null : _resetCapture,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      isNextEnabled: _captured && !_isLoading,
      onNext: _submitAndAnalyze,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
