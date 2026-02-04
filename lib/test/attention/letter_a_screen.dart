import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/test_session.dart';
import 'subtraction_screen.dart';

class LetterAScreen extends StatefulWidget {
  const LetterAScreen({super.key});

  @override
  State<LetterAScreen> createState() => _LetterAScreenState();
}

class _LetterAScreenState extends State<LetterAScreen> {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _instructionPlayer = AudioPlayer(); // مشغل التعليمات التلقائي

  // ===== السلسلة المرجعية النهائية =====
  // و ب أ ج م ن أ أ ي خ ل ب أ و أ خ د ه أ أ أ ي أ م ص و أ أ ب
  final List<bool> _letterTimeline = [
    false, // 0  و
    false, // 1  ب
    true,  // 2  أ
    false, // 3  ج
    false, // 4  م
    false, // 5  ن
    true,  // 6  أ
    true,  // 7  أ
    false, // 8  ي
    false, // 9  خ
    false, // 10 ل
    false, // 11 ب
    true,  // 12 أ
    false, // 13 و
    true,  // 14 أ
    false, // 15 خ
    false, // 16 د
    false, // 17 ه
    true,  // 18 أ
    true,  // 19 أ
    true,  // 20 أ
    false, // 21 ي
    true,  // 22 أ
    false, // 23 م
    false, // 24 ص
    false, // 25 و
    true,  // 26 أ
    true,  // 27 أ
    false, // 28 ب
  ];

  int _currentIndex = 0;
  int _falsePresses = 0;
  final Set<int> _correctHits = {};

  bool _isPlaying = false;
  bool _isDone = false;
  bool _feedback = false;
  bool _showRepeatButton = false; // التحكم في ظهور زر السكافولد

  @override
  void initState() {
    super.initState();
    
    // إعداد مستمع لانتهاء صوت التعليمات
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted && !_isPlaying) {
        setState(() => _showRepeatButton = true);
      }
    });

    // تشغيل التعليمات تلقائياً عند دخول الصفحة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playInstructions();
    });
  }

  // دالة تشغيل التعليمات
  Future<void> _playInstructions() async {
    setState(() => _showRepeatButton = false);
    await _instructionPlayer.stop();
    await _instructionPlayer.play(AssetSource('audio/letter_a_instructions.mp3'));
  }

  // ===== بدء السؤال =====
  Future<void> _start() async {
    await _instructionPlayer.stop(); // إيقاف التعليمات فور البدء
    setState(() {
      _currentIndex = 0;
      _falsePresses = 0;
      _correctHits.clear();
      _isDone = false;
      _isPlaying = true;
      _showRepeatButton = false; // إخفاء الزر نهائياً عند البدء
    });

    _advanceIndex();

    await _player.play(AssetSource('audio/attention-a.mp3'));

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _calculateScore();
      setState(() {
        _isPlaying = false;
        _isDone = true;
      });
    });
  }

  // ===== تحريك المؤشر (تقريبي غير حساس للزمن) =====
  void _advanceIndex() async {
    // ⏳ انتظار مدة المقدمة (17 ثانية) قبل بدء عد الحروف برمجياً
    await Future.delayed(const Duration(seconds: 17));

    for (int i = 0; i < _letterTimeline.length; i++) {
      if (!_isPlaying) break;
      _currentIndex = i; // تحديث المؤشر أولاً ليتوافق مع الحرف المسموع
      await Future.delayed(const Duration(milliseconds: 900));
    }
  }

  // ===== عند النقر =====
  void _onTap() {
    if (!_isPlaying) return;

    setState(() => _feedback = true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _feedback = false);
    });

    final isA = _letterTimeline[_currentIndex];

    if (isA) {
      _correctHits.add(_currentIndex);
    } else {
      _falsePresses++;
    }
  }

  // ===== حساب النتيجة (بدون طباعة) =====
  void _calculateScore() {
    int missedA = 0;

    for (int i = 0; i < _letterTimeline.length; i++) {
      if (_letterTimeline[i] && !_correctHits.contains(i)) {
        missedA++;
      }
    }

    final totalErrors = _falsePresses + missedA;
    TestSession.letterAScore = totalErrors <= 1 ? 1 : 0;
  }

  @override
  void dispose() {
    _player.dispose();
    _instructionPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'حرف الألف',
      instruction:
          'اضغط على الدائرة فقط عند سماع حرف (أ). لا تضغط عند أي حرف آخر.',
      // يظهر الزر فقط إذا انتهى الصوت ولم يبدأ الاختبار بعد
      onRepeatInstruction: _showRepeatButton ? _playInstructions : null,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ===== زر البدء =====
          if (!_isPlaying && !_isDone)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // ✅ التعديل هنا: الزر يكون معطلاً (null) طالما لم ينتهِ الصوت بعد
                onPressed: _showRepeatButton ? _start : null, 
                child: const Text('ابدأ'),
              ),
            ),

          const SizedBox(height: 40),

          // ===== زر التفاعل =====
          GestureDetector(
            onTap: _onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _feedback
                    ? Colors.white
                    : (_isPlaying ? Colors.red : Colors.grey),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: _feedback
                    ? [
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  _isDone
                      ? 'أنهيت الإجابة'
                      : (_isPlaying ? 'اضغط عند (أ)' : 'انتظر'),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _feedback ? Colors.red : Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        
        ],
      ),

      // ===== إنهاء وتحليل =====
      isNextEnabled: _isDone,
      onNext: () {
        // ===== الطباعة النهائية =====
        final int totalA =
            _letterTimeline.where((e) => e).length;
        final int missedA =
            totalA - _correctHits.length;
        final int totalErrors =
            _falsePresses + missedA;

        print('===== Letter A Final Result =====');
        print('False presses: $_falsePresses');
        print('Missed A: $missedA');
        print('Total errors: $totalErrors');
        print('Final Score: ${TestSession.letterAScore}');
        print('================================');


        TestSession.nextQuestion();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SubtractionScreen(),
          ),
        );
      },
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}