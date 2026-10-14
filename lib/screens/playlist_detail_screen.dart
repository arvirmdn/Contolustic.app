import 'dart:math';

import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../services/download_service.dart';
import '../services/playlist_service.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/thumb.dart';
import 'player_screen.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Playlist? _playlist;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    PlaylistService.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    PlaylistService.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final all = await PlaylistService.instance.loadAll();
    final match = all.where((p) => p.id == widget.playlistId);
    if (!mounted) return;
    setState(() {
      _gone = match.isEmpty;
      _playlist = match.isEmpty ? null : match.first;
    });
  }

  Future<void> _rename() async {
    final p = _playlist;
    if (p == null) return;
    final name = await askPlaylistName(context, initial: p.name);
    if (name == null) return;
    await PlaylistService.instance.rename(p.id, name);
  }

  Future<void> _delete() async {
    final p = _playlist;
    if (p == null) return;
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus "${p.name}"?'),
        content: const Text('Playlist akan dihapus. Lagu di perangkat tidak ikut terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    await PlaylistService.instance.delete(p.id);
    navigator.pop();
  }

  /// Mengganti lagu dengan versi unduhan (offline) jika ada.
  Future<List<Song>> _resolved(List<Song> songs) async {
    final downloaded = await DownloadService.instance.loadAll();
    return songs.map((s) => preferDownloaded(s, downloaded)).toList();
  }

  Future<void> _playFrom(int index) async {
    final p = _playlist;
    if (p == null) return;
    final queue = await _resolved(p.songs);
    if (!mounted) return;
    await playAndOpen(context, queue[index], queue: queue);
  }

  Future<void> _playAll({required bool shuffle}) async {
    final p = _playlist;
    if (p == null || p.songs.isEmpty) return;
    final queue = await _resolved(p.songs);
    if (!mounted) return;
    final start = shuffle ? Random().nextInt(queue.length) : 0;
    await playAndOpen(context, queue[start], queue: queue, shuffle: shuffle);
  }

  @override
  Widget build(BuildContext context) {
    final p = _playlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(p?.name ?? 'Playlist', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: p == null
            ? null
            : [
                IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _rename),
                IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
              ],
      ),
      body: _gone
          ? const Center(child: Text('Playlist sudah dihapus'))
          : p == null
              ? const Center(child: CircularProgressIndicator())
              : p.songs.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Playlist ini masih kosong.\nTambahkan lagu lewat ikon playlist di pencarian atau layar pemutar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: p.songs.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Putar'),
                                    onPressed: () => _playAll(shuffle: false),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.shuffle),
                                    label: const Text('Acak'),
                                    onPressed: () => _playAll(shuffle: true),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final index = i - 1;
                        final song = p.songs[index];
                        return ListTile(
                          leading: SongThumb(url: song.thumbnailUrl),
                          title: Text(song.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                          subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => PlaylistService.instance.removeSong(p.id, song.id),
                          ),
                          onTap: () => _playFrom(index),
                        );
                      },
                    ),
    );
  }
}
