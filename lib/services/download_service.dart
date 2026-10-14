import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import 'youtube_service.dart';

class DownloadService {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  static const _prefsKey = 'downloads_v1';

  /// Naik setiap kali daftar unduhan berubah.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  final YoutubeService _yt = YoutubeService.instance;

  /// Daftar lagu yang file-nya masih ada di perangkat.
  Future<List<Song>> loadAll() async {
    final all = await _readRaw();
    return all
        .where((s) => s.localPath != null && File(s.localPath!).existsSync())
        .toList();
  }

  Future<void> download(Song song) async {
    final info = await _yt.getBestAudio(song.id);

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/music')..createSync(recursive: true);
    final ext = info.container.name.toLowerCase() == 'webm' ? 'webm' : 'm4a';
    final file = File('${dir.path}/${song.id}.$ext');

    try {
      final sink = file.openWrite();
      try {
        await sink.addStream(_yt.openStream(info));
      } finally {
        await sink.close();
      }
    } catch (_) {
      if (file.existsSync()) file.deleteSync();
      rethrow;
    }

    final saved = Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      thumbnailUrl: song.thumbnailUrl,
      duration: song.duration,
      localPath: file.path,
    );
    final all = (await _readRaw()).where((s) => s.id != song.id).toList()
      ..add(saved);
    await _writeRaw(all);
  }

  Future<void> delete(Song song) async {
    final all = await _readRaw();
    for (final s in all.where((s) => s.id == song.id)) {
      final path = s.localPath;
      if (path != null && File(path).existsSync()) File(path).deleteSync();
    }
    await _writeRaw(all.where((s) => s.id != song.id).toList());
  }

  Future<List<Song>> _readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    return Song.listFromJson(raw);
  }

  Future<void> _writeRaw(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, Song.listToJson(songs));
    changes.value++;
  }
}
