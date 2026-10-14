import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';
import 'youtube_service.dart';

class PlayerService {
  PlayerService._() {
    // Lagu selesai -> lanjut ke lagu berikutnya di antrean.
    player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        next().catchError((Object e) => debugPrint('Gagal lanjut: $e'));
      }
    });
  }
  static final PlayerService instance = PlayerService._();

  /// Diisi true di main() jika notifikasi background berhasil diinisialisasi.
  /// Jika false, lagu tetap diputar tanpa notifikasi.
  static bool backgroundReady = false;

  final AudioPlayer player = AudioPlayer();

  /// Lagu yang sedang dimuat/diputar (dipakai mini player dan layar pemutar).
  final ValueNotifier<Song?> current = ValueNotifier<Song?>(null);

  /// Mode acak. Saat dinyalakan, urutan lagu diacak ulang.
  final ValueNotifier<bool> shuffle = ValueNotifier<bool>(false);

  /// Daftar asli dari pengguna (urutan playlist/hasil).
  List<Song> _original = [];

  /// Urutan putar yang sebenarnya (sudah diacak jika mode acak aktif).
  List<Song> _order = [];
  int _cursor = 0;

  /// Memutar satu lagu sebagai antrean berisi satu lagu.
  Future<void> play(Song song) => playQueue([song]);

  /// Memutar daftar lagu. [startIndex] adalah lagu pertama yang diputar.
  Future<void> playQueue(
    List<Song> songs, {
    int startIndex = 0,
    bool shuffleOn = false,
  }) async {
    if (songs.isEmpty) return;
    _original = List.of(songs);
    shuffle.value = shuffleOn;
    final first = _original[startIndex.clamp(0, _original.length - 1)];
    _buildOrder(first);
    await _playCurrent();
  }

  Future<void> next() async {
    if (_order.isEmpty) return;
    _cursor = (_cursor + 1) % _order.length;
    await _playCurrent();
  }

  /// Jika sudah lewat 3 detik, kembali ke awal lagu. Jika belum, ke lagu sebelumnya.
  Future<void> previous() async {
    if (_order.isEmpty) return;
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }
    _cursor = (_cursor - 1 + _order.length) % _order.length;
    await _playCurrent();
  }

  /// Menyalakan/mematikan mode acak tanpa menghentikan lagu yang sedang diputar.
  void toggleShuffle() {
    shuffle.value = !shuffle.value;
    if (_order.isEmpty) return;
    _buildOrder(_order[_cursor]);
  }

  /// Menyusun ulang urutan agar [first] berada di posisi pertama.
  void _buildOrder(Song first) {
    final idx = _original.indexWhere((s) => s.id == first.id);
    if (shuffle.value) {
      final rest = [..._original]..removeWhere((s) => s.id == first.id);
      rest.shuffle(Random());
      _order = [first, ...rest];
    } else {
      final start = idx < 0 ? 0 : idx;
      _order = [..._original.sublist(start), ..._original.sublist(0, start)];
    }
    _cursor = 0;
  }

  Future<void> _playCurrent() async {
    final song = _order[_cursor];

    final MediaItem? tag = backgroundReady
        ? MediaItem(
            id: song.id,
            title: song.title,
            artist: song.artist,
            artUri: song.thumbnailUrl.isEmpty ? null : Uri.parse(song.thumbnailUrl),
            duration: song.duration,
          )
        : null;

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
