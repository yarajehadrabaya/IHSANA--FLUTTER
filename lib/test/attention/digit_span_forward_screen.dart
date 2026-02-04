import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../../utils/moca_api_service.dart';
import 'digit_span_backward_screen.dart';

class DigitSpanForwardScreen extends StatefulWidget {
  const DigitSpanForwardScreen({super.key});

  @override
  State<DigitSpanForwardScreen> createState() =>
      _DigitSpanForwardScreenState();
}

class _DigitSpanForwardScreenState extends State<DigitSpanForwardScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _actionAudioPlayer = AudioPlayer(); // 🔊 جديد
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _audioFinished = false;
  bool _hasPlayedOnce = false;

  String? _recordedPath;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  // 🔊 سماع الأرقام
  Future<void> _playInstruction() async {
    setState(() {
      _isPlaying = true;
      _audioFinished = false;
      _hasPlayedOnce = true;
    });

    _pulseController.repeat(reverse: true);

    await _instructionPlayer.play(
      AssetSource('audio/forword.mp3'),
    );

    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        _pulseController.stop();
        setState(() {
          _isPlaying = false;
          _audioFinished = true;
        });
      }
    });
  }

  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
    } else {
      await _recordFromMobile();
    }
  }

  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/digits_forward_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
    }
  }

  Future<void> _recordFromHardware() async {
    final baseUrl = SessionContext.raspberryBaseUrl;

    if (_isRecording) {
      setState(() => _isLoading = true);
      try {
        await http.post(Uri.parse('$baseUrl/stop-recording'));
        final res = await http.get(Uri.parse('$baseUrl/get-audio'));

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/digits_forward_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _recordedPath = file.path;
          _isRecording = false;
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await http.post(Uri.parse('$baseUrl/start-recording'));
      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_recordedPath == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAttention(
        _recordedPath!,
        "digits-forward",
      );

      TestSession.forwardScore = result['score'] ?? 0;

      if (!mounted) return;
      TestSession.nextQuestion();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DigitSpanBackwardScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔊 أصوات الأزرار (فقط إضافة)
  Future<void> _playActionVoice(String asset) async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _stopActionVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _instructionPlayer.dispose();
    _actionAudioPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHardware = SessionContext.testMode == TestMode.hardware;

    return TestQuestionScaffold(
      title: 'الأرقام للأمام',
      instruction:
          'اضغط على زر سماع الأرقام مرة واحدة، ثم أعد تكرارها بنفس الترتيب.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ===== CARD (كما هو) =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ===== سماعة تنبض =====
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isPlaying
                        ? (0.95 + (_pulseController.value * 0.15))
                        : 1.0;

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPlaying
                              ? Colors.blue.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.12),
                        ),
                        child: Icon(
                          Icons.volume_up,
                          size: 64,
                          color:
                              _isPlaying ? Colors.blue : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

              // ===== زر سماع الأرقام =====
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    // 🔊 نطق اسم الزر عند الضغط المطول
                    onLongPressStart: (_) {
                      if (!(_hasPlayedOnce || _isPlaying || _isRecording)) {
                        _playActionVoice('audio/listen_numbers.mp3');
                      }
                    },
                    // ⏹️ إيقاف الصوت عند رفع الإصبع
                    onLongPressEnd: (_) => _stopActionVoice(),
                    child: ElevatedButton.icon(
                      onPressed:
                          (_hasPlayedOnce || _isPlaying || _isRecording)
                              ? null
                              : () {
                                  _stopActionVoice(); // إيقاف صوت المعاينة فوراً لبدء تشغيل الأرقام
                                  _playInstruction();
                                },
                      icon: const Icon(Icons.volume_up),
                      label: const Text('سماع الأرقام'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== زر تسجيل / إعادة التسجيل =====
                GestureDetector(
                  // 🔊 نطق وظيفة الزر الحالية عند الضغط المطول فقط
                  onLongPressStart: (_) {
                    if (_isRecording) {
                      _playActionVoice('audio/stop_recording.mp3');
                    } else if (_recordedPath != null) {
                      _playActionVoice('audio/retry_recording.mp3');
                    } else {
                      _playActionVoice('audio/start_recording.mp3');
                    }
                  },
                  onLongPressEnd: (_) => _stopActionVoice(),
                  onTapCancel: _stopActionVoice,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (!_audioFinished ||
                              _isPlaying ||
                              _isLoading)
                          ? null
                          : () {
                              _stopActionVoice(); // إيقاف صوت المعاينة فوراً لبدء الفعل
                              _onRecordPressed();
                            },
                      icon: Icon(
                        isHardware
                            ? (_isRecording
                                ? Icons.stop
                                : Icons.settings_remote)
                            : (_isRecording
                                ? Icons.stop
                                : Icons.mic),
                      ),
                      label: Text(
                        _isRecording
                            ? 'إيقاف التسجيل'
                            : (_recordedPath != null
                                ? 'إعادة التسجيل'
                                : 'تسجيل الإجابة'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRecording ? Colors.red : null,
                        foregroundColor:
                            _isRecording ? Colors.white : null,
                      ),
                    ),
                  ),
                ),

                // ===== جاري التسجيل =====
                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: const [
                        Icon(Icons.fiber_manual_record,
                            color: Colors.red, size: 28),
                        SizedBox(height: 6),
                        Text(
                          'جاري التسجيل...',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_recordedPath != null && !_isRecording)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'تم تسجيل الإجابة بنجاح',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      isNextEnabled:
          _recordedPath != null && !_isRecording && !_isLoading,
      onNext: _submit,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
