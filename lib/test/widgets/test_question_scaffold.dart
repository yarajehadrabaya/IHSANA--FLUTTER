import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../utils/test_session.dart';

class TestQuestionScaffold extends StatefulWidget {
  final String title;
  final String? instruction;
  final Widget content;
  final VoidCallback onNext;
  final VoidCallback onEndSession;
  final bool isNextEnabled;

  /// 🆕 إضافة باراميتر اختياري لاستقبال دالة إعادة تشغيل الصوت
  final VoidCallback? onRepeatInstruction;

  /// ❌ موجود فقط لمنع كسر الكود القديم – غير مستخدم
  final bool allowMute;

  const TestQuestionScaffold({
    super.key,
    required this.title,
    this.instruction,
    required this.content,
    required this.onNext,
    required this.onEndSession,
    this.isNextEnabled = true,
    this.allowMute = true,
    this.onRepeatInstruction, // استقبال الدالة هنا
  });

  @override
  State<TestQuestionScaffold> createState() =>
      _TestQuestionScaffoldState();
}

class _TestQuestionScaffoldState extends State<TestQuestionScaffold> {
  final AudioPlayer _actionAudioPlayer = AudioPlayer();

  @override
  void dispose() {
    _actionAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playActionVoice(String asset) async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(
        AssetSource(asset),
      );
    } catch (_) {}
  }

  Future<void> _stopActionVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'سؤال ${TestSession.currentQuestion} / ${TestSession.totalQuestions}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),

                        // ===== التعديل: صف أزرار التحكم العلوية =====
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // زر إنهاء الجلسة الأصلي
                            GestureDetector(
                              onTapDown: (_) =>
                                  _playActionVoice('audio/end_session.mp3'),
                              onTapUp: (_) => _stopActionVoice(),
                              onTapCancel: _stopActionVoice,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _showEndSessionDialog(context),
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
                            ),

                            // 🆕 زر إعادة السؤال (يظهر فقط عند تمرير دالة وغير null)
                            if (widget.onRepeatInstruction != null) ...[
                              const SizedBox(width: 8),
                              const Text('|', style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: widget.onRepeatInstruction,
                                icon: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  'إعادة السؤال',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        if (widget.instruction != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primary.withOpacity(0.06),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.instruction!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: widget.content,
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),

              // ===== زر إنهاء وتحليل =====
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: GestureDetector(
                  onTapDown: (_) {
                    if (widget.isNextEnabled) {
                      _playActionVoice(
                          'audio/submit_and_analyze.mp3');
                    }
                  },
                  onTapUp: (_) => _stopActionVoice(),
                  onTapCancel: _stopActionVoice,
                  child: ElevatedButton(
                    onPressed: widget.isNextEnabled
                        ? widget.onNext
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'إنهاء وتحليل',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الجلسة'),
        content: const Text(
          'هل أنت متأكد أنك تريد إنهاء الجلسة؟ سيتم فقدان التقدم الحالي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onEndSession();
            },
            child: const Text(
              'إنهاء',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}