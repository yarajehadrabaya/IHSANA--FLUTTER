import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
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
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _camelPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder();
      _recorder!.openRecorder();
    }

    _playInstruction();
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    await _instructionPlayer.play(
      AssetSource('audio/naming.mp3'),
    );
  }

  // 🎤 زر التسجيل الموحد
  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
    } else {
      await _recordFromMobile();
    }
  }

  // 📱 تسجيل من الموبايل
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _camelPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/camel.wav';

      await _recorder!.startRecorder(
        toFile: path,
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

  // 🖥️ تسجيل من Raspberry Pi (نفس Rhino 100%)
  Future<void> _recordFromHardware() async {
    setState(() => _isLoading = true);

    try {
      final baseUrl = SessionContext.raspberryBaseUrl;

      // 1️⃣ اطلب التسجيل
      await http.post(Uri.parse('$baseUrl/record'));

      // 2️⃣ حمّل الملف
      final res = await http.get(Uri.parse('$baseUrl/audio'));

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/camel_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _camelPath = file.path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التسجيل الخارجي: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🚀 إرسال الملفات الثلاثة للموديل
  Future<void> _submit() async {
    if (_camelPath == null) return;

    setState(() => _isLoading = true);

    try {
      final audios = [
        widget.lionPath,
        widget.rhinoPath,
        _camelPath!,
      ];

      final res = await _apiService.checkNaming(audios);
      TestSession.namingScore = res['score'] ?? 0;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MemoryEncodingScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحليل الاختبار: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'تسمية الحيوانات',
          instruction: 'ما اسم هذا الحيوان؟',
          content: Column(
            children: [
              Image.asset(
                'assets/images/camel.png',
                height: 200,
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onRecordPressed,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(
                  _isRecording ? 'إيقاف التسجيل' : 'تسجيل الإجابة',
                ),
              ),

              const SizedBox(height: 16),

              if (_camelPath != null && !_isRecording)
                const Text(
                  '✅ تم تسجيل الإجابة',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          isNextEnabled: _camelPath != null && !_isRecording && !_isLoading,
          onNext: _submit,
          onEndSession: () =>
              Navigator.popUntil(context, (r) => r.isFirst),
        ),

        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'جاري التسجيل من الجهاز...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
