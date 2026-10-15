import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../services/playlist_service.dart';
import '../widgets/add_to_playlist.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  /// true jika ditampilkan di dalam tab Pustaka (tanpa AppBar sendiri).
  final bool embedded;
  const PlaylistsScreen({super.key, this.embedded = false});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  List<Playlist> _playlists = [];

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
    final lists = await PlaylistService.instance.loadAll();
    if (mounted) setState(() => _playlists = lists);
  }

  Future<void> _create() async {
    final name = await askPlaylistName(context);
    if (name == null) return;
    await PlaylistService.instance.create(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Playlist')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Buat'),
        onPressed: _create,
      ),
      body: _playlists.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada playlist.\nTekan Buat untuk memulai.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: _playlists.length,
              itemBuilder: (context, i) {
                final p = _playlists[i];
                return ListTile(
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.queue_music),
                  ),
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${p.songs.length} lagu'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(playlistId: p.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
