import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import '../attention/digit_span_forward_screen.dart';

class MemoryEncodingScreen extends StatefulWidget {
  const MemoryEncodingScreen({super.key});
  @override
  State<MemoryEncodingScreen> createState() => _MemoryEncodingScreenState();
}

class _MemoryEncodingScreenState extends State<MemoryEncodingScreen> {
  final AudioPlayer _player = AudioPlayer();
  int _count = 0;
  bool _isPlaying = false;

  Future<void> _play() async {
    setState(() {
      _isPlaying = true;
      _count++;
    });
    await _player.play(AssetSource('audio/memory-repeat.mp3'));
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'حفظ الكلمات',
      content: Column(
        children: [
          Icon(
            Icons.volume_up,
            size: 80,
            color: _isPlaying ? Colors.blue : Colors.grey,
          ),
          Text(
            "مرات الاستماع: $_count / 2",
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: (_count < 2 && !_isPlaying) ? _play : null,
            child: const Text("تشغيل الكلمات"),
          ),
        ],
      ),
      isNextEnabled: _count == 2 && !_isPlaying,
      onNext: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DigitSpanForwardScreen()),
      ),
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
