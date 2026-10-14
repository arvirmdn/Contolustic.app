import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';
import '../models/song.dart';

/// Menyimpan playlist di perangkat (SharedPreferences).
class PlaylistService {
  PlaylistService._();
  static final PlaylistService instance = PlaylistService._();

  static const _prefsKey = 'playlists_v1';

  /// Naik setiap kali isi playlist berubah.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<Playlist>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Playlist> create(String name) async {
    final all = await loadAll();
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
    );
    await _save([...all, playlist]);
    return playlist;
  }

  Future<void> rename(String playlistId, String name) =>
      _update(playlistId, (p) => p.copyWith(name: name));

  Future<void> delete(String playlistId) async {
    final all = await loadAll();
    await _save(all.where((p) => p.id != playlistId).toList());
  }

  /// Menambah lagu. Lagu yang sudah ada di playlist tidak ditambahkan lagi.
  /// Mengembalikan false jika lagu sudah ada.
  Future<bool> addSong(String playlistId, Song song) async {
    final all = await loadAll();
    final target = all.firstWhere((p) => p.id == playlistId);
    if (target.songs.any((s) => s.id == song.id)) return false;
    await _save(all
        .map((p) => p.id == playlistId
            ? p.copyWith(songs: [...p.songs, song])
            : p)
        .toList());
    return true;
  }

  Future<void> removeSong(String playlistId, String songId) =>
      _update(
        playlistId,
        (p) => p.copyWith(songs: p.songs.where((s) => s.id != songId).toList()),
      );

  Future<void> _update(
    String playlistId,
    Playlist Function(Playlist) change,
  ) async {
    final all = await loadAll();
    await _save(all.map((p) => p.id == playlistId ? change(p) : p).toList());
  }

  Future<void> _save(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(playlists.map((p) => p.toJson()).toList()),
    );
    changes.value++;
  }
}

/// Dipakai untuk mencari versi unduhan dari lagu (jika ada).
Song preferDownloaded(Song song, List<Song> downloaded) {
  final matches = downloaded.where((s) => s.id == song.id);
  return matches.isEmpty ? song : matches.first;
}
