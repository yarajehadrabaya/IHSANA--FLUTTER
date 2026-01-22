import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../session/session_context.dart';

class HardwareCaptureService {
  /// 🎤 التقاط صوت من Raspberry Pi
  static Future<String> captureAudio() async {
    final uri =
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');

    final res = await http.get(uri).timeout(
      const Duration(seconds: 30),
    );

    if (res.statusCode != 200) {
      throw Exception('Hardware audio error ${res.statusCode}');
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/hw_audio_${DateTime.now().millisecondsSinceEpoch}.wav',
    );

    await file.writeAsBytes(res.bodyBytes);
    return file.path;
  }

  /// 📷 (للمستقبل) التقاط صورة
  static Future<String> captureImage() async {
    final uri =
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-image');

    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception('Hardware image error ${res.statusCode}');
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/hw_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    await file.writeAsBytes(res.bodyBytes);
    return file.path;
  }
}
