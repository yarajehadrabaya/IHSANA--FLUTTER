import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioSession {
  /// 🔇 notifier لحالة الصوت
  static final ValueNotifier<bool> mutedNotifier =
      ValueNotifier<bool>(false);

  /// 🧠 player -> آخر source شغّله
  static final Map<AudioPlayer, Source?> _players =
      <AudioPlayer, Source?>{};

  /// تسجيل player
  static void register(AudioPlayer player) {
    _players[player] = null;
    player.setVolume(mutedNotifier.value ? 0 : 1);
  }

  /// إزالة player
  static void unregister(AudioPlayer player) {
    _players.remove(player);
  }

  /// تشغيل صوت (يحفظ المصدر)
  static Future<void> play(
    AudioPlayer player,
    Source source,
  ) async {
    _players[player] = source;

    if (mutedNotifier.value) return;

    await player.stop();
    await player.play(source, volume: 1);
  }

  /// 🔥 إيقاف جميع الأصوات فورًا (حل مشكلتك)
  static Future<void> stopAll() async {
    for (final AudioPlayer player in _players.keys) {
      try {
        await player.stop();
      } catch (_) {}
    }
  }

  /// كتم كل الأصوات
  static Future<void> muteAll() async {
    mutedNotifier.value = true;
    for (final AudioPlayer p in _players.keys) {
      await p.setVolume(0);
    }
  }

  /// تشغيل الأصوات من البداية
  static Future<void> unmuteAll() async {
    mutedNotifier.value = false;

    for (final MapEntry<AudioPlayer, Source?> entry
        in _players.entries) {
      final AudioPlayer player = entry.key;
      final Source? source = entry.value;

      if (source != null) {
        await player.stop();
        await player.play(source, volume: 1);
      }
    }
  }
}
