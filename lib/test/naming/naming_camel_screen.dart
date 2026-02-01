import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../memory/memory_encoding_screen.dart';

class NamingCamelScreen extends StatefulWidget {
  final String lionPath;
  final String rhinoPath;

  const NamingCamelScreen({
    super.key,
    required this.lionPath,
    required this.rhinoPath,
  });

  @override
  State<NamingCamelScreen> createState() => _NamingCamelScreenState();
}

class _NamingCamelScreenState extends State<NamingCamelScreen> {
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _camelPath;

  @override
  void initState() {
    super.initState();
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    super.dispose();
  }

  // ================= 🎛 RECORD BUTTON =================
  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      if (_isRecording) {
        await _stopHardwareRecording();
      } else {
        await _startHardwareRecording();
      }
    } else {
      await _recordFromMobile();
    }
  }

  // ================= 📱 MOBILE =================
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _camelPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/camel_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _camelPath = null;
      });
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _startHardwareRecording() async {
    setState(() {
      _isRecording = true;
      _camelPath = null;
    });

    await http.post(
      Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
    );
  }

  Future<void> _stopHardwareRecording() async {
    setState(() => _isLoading = true);

    try {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final res = await http.get(
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
      );

      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/camel_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _camelPath = file.path;
          _isRecording = false;
        });
      } else {
        throw Exception('Hardware error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في تسجيل الجهاز الخارجي')),
      );
      setState(() => _isRecording = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submitAndAnalyze() async {
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkNaming([
        widget.lionPath,
        widget.rhinoPath,
        _camelPath!,
      ]);

      TestSession.namingScore = result['score'] ?? 0;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('اكتمل قسم التسمية'),
          content: Text('السكور: ${result['score']} / 3'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemoryEncodingScreen(),
                  ),
                );
              },
              child: const Text('متابعة'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'آخر حيوان',
          content: Column(
            children: [
              Image.asset('assets/images/camel.png', height: 200),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onRecordPressed,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  _isRecording ? 'إيقاف التسجيل' : 'تسجيل الإجابة',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : null,
                  foregroundColor: _isRecording ? Colors.white : null,
                ),
              ),

              if (_camelPath != null && !_isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '✅ تم تسجيل الجمل بنجاح',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
          isNextEnabled:
              _camelPath != null && !_isRecording && !_isLoading,
          onNext: _submitAndAnalyze,
          onEndSession: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),

        if (_isLoading)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}