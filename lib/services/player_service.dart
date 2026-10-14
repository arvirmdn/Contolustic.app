import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';
import 'youtube_service.dart';

class PlayerService {
  PlayerService._();
  static final PlayerService instance = PlayerService._();

  final AudioPlayer player = AudioPlayer();

  /// Lagu yang sedang dimuat/diputar (dipakai mini player).
  final ValueNotifier<Song?> current = ValueNotifier<Song?>(null);

  Future<void> play(Song song) async {
    final tag = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: song.thumbnailUrl.isEmpty ? null : Uri.parse(song.thumbnailUrl),
      duration: song.duration,
    );

    final AudioSource source;
    if (song.localPath != null) {
      source = AudioSource.file(song.localPath!, tag: tag);
    } else {
      final info = await YoutubeService.instance.getBestAudio(song.id);
      source = AudioSource.uri(info.url, tag: tag);
    }

    await player.setAudioSource(source);
    current.value = song;
    // Jangan di-await: Future dari play() baru selesai saat lagu berhenti.
    player.play();
  }
}
