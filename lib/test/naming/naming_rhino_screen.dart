import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import 'naming_camel_screen.dart';

class NamingRhinoScreen extends StatefulWidget {
  final String lionAudioPath;
  const NamingRhinoScreen({super.key, required this.lionAudioPath});

  @override
  State<NamingRhinoScreen> createState() => _NamingRhinoScreenState();
}

class _NamingRhinoScreenState extends State<NamingRhinoScreen> {
  FlutterSoundRecorder? _recorder;

  bool _isRecording = false;
  bool _isLoading = false;
  String? _rhinoPath;

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

  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _rhinoPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/rhino_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _rhinoPath = null;
      });
    }
  }

  Future<void> _startHardwareRecording() async {
    setState(() {
      _isRecording = true;
      _rhinoPath = null;
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
        final file = File('${dir.path}/rhino_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _rhinoPath = file.path;
          _isRecording = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'تسمية الحيوانات',
      content: Column(
        children: [
          Image.asset('assets/images/rhino.png', height: 200),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _onRecordPressed,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                  _isRecording ? 'إيقاف التسجيل' : 'تسجيل الإجابة'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                backgroundColor: _isRecording ? Colors.red : null,
                foregroundColor: _isRecording ? Colors.white : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (_isRecording)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('🎙️ جاري التسجيل...',
                  style: TextStyle(color: Colors.red)),
            ),

          if (_rhinoPath != null && !_isRecording)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('✅ تم حفظ تسجيل وحيد القرن',
                  style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
      isNextEnabled: _rhinoPath != null && !_isRecording && !_isLoading,
      onNext: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NamingCamelScreen(
              lionPath: widget.lionAudioPath,
              rhinoPath: _rhinoPath!,
            ),
          ),
        );
      },
      onEndSession: () =>
          Navigator.popUntil(context, (route) => route.isFirst),
    );
  }
}
