import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/download_service.dart';
import '../services/youtube_service.dart';
import '../utils/format.dart';
import '../widgets/add_to_playlist.dart';
import '../widgets/thumb.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  final _downloading = <String>{};
  List<Song> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await YoutubeService.instance.search(q);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = 'Pencarian gagal: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _download(Song song) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading.add(song.id));
    try {
      await DownloadService.instance.download(song);
      messenger.showSnackBar(
        SnackBar(content: Text('Tersimpan: ${song.title}')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Unduhan gagal: $e')));
    } finally {
      if (mounted) setState(() => _downloading.remove(song.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metrolist')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari lagu atau artis',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_loading
                ? const Center(child: Text('Ketik sesuatu untuk mencari'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final song = _results[i];
                      final busy = _downloading.contains(song.id);
                      return ListTile(
                        leading: SongThumb(url: song.thumbnailUrl),
                        title: Text(
                          song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.duration == null
                              ? song.artist
                              : '${song.artist} • ${fmtDuration(song.duration!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.playlist_add),
                              onPressed: () => showAddToPlaylist(context, song),
                            ),
                            busy
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.download_outlined),
                                    onPressed: () => _download(song),
                                  ),
                          ],
                        ),
                        onTap: () => playAndOpen(context, song, queue: _results),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
