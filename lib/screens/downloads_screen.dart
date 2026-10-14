import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/download_service.dart';
import '../widgets/thumb.dart';
import 'player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    DownloadService.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    DownloadService.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final songs = await DownloadService.instance.loadAll();
    if (mounted) setState(() => _songs = songs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unduhan')),
      body: _songs.isEmpty
          ? const Center(child: Text('Belum ada lagu yang diunduh'))
          : ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, i) {
                final song = _songs[i];
                return ListTile(
                  leading: Thumb(url: song.thumbnailUrl),
                  title: Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => DownloadService.instance.delete(song),
                  ),
                  onTap: () => playAndOpen(context, song),
                );
              },
            ),
    );
  }
}
