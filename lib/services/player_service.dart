import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'history_service.dart';
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

    if (song.localPath != null) {
      await player.setAudioSource(AudioSource.file(song.localPath!));
    } else {
      await _setStreamSource(song.id);
    }

    current.value = song;
    HistoryService.instance.add(song).catchError((Object _) {});
    // Jangan di-await: Future dari play() baru selesai saat lagu berhenti.
    player.play();
  }

  /// Mencoba beberapa kandidat stream YouTube sampai ada yang bisa diputar.
  Future<void> _setStreamSource(String videoId) async {
    final candidates = await YoutubeService.instance.getAudioCandidates(videoId);
    Object? lastError;
    for (final info in candidates) {
      // Coba tanpa header dulu (URL dari client YouTube biasanya cocok begini),
      // lalu dengan header sebagai cadangan.
      for (final headers in <Map<String, String>?>[null, _streamHeaders]) {
        try {
          await player.setAudioSource(
            AudioSource.uri(info.url, headers: headers),
          );
          return;
        } catch (e) {
          debugPrint(
            'Stream gagal (header=${headers != null}, bitrate=${info.bitrate}): $e',
          );
          lastError = e;
        }
      }
    }
    throw lastError ?? Exception('Tidak ada stream audio yang bisa diputar');
  }

  static const _streamHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
  };
}
