import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

/// Riwayat lagu yang pernah diputar (terbaru di depan), disimpan di perangkat.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _prefsKey = 'history_v1';
  static const _maxItems = 30;

  /// Naik setiap kali riwayat berubah.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  Future<List<Song>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    return Song.listFromJson(raw);
  }

  Future<void> add(Song song) async {
    final all = await loadAll();
    final updated = [song, ...all.where((s) => s.id != song.id)]
        .take(_maxItems)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, Song.listToJson(updated));
    changes.value++;
  }
}
