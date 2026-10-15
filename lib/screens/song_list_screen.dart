import 'package:flutter/material.dart';

import '../models/song.dart';
import '../widgets/thumb.dart';
import 'player_screen.dart';

/// Daftar lagu sederhana (hasil mood, riwayat, populer). Lagu bisa langsung diputar.
class SongListScreen extends StatefulWidget {
  final String title;
  final Future<List<Song>> Function() loader;

  const SongListScreen({
    super.key,
    required this.title,
    required this.loader,
  });

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  late final Future<List<Song>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Song>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Gagal memuat: ${snap.error}'));
          }
          final songs = snap.data ?? [];
          if (songs.isEmpty) {
            return const Center(child: Text('Tidak ada lagu'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: songs.length,
            itemBuilder: (context, i) {
              final song = songs[i];
              return ListTile(
                leading: SongThumb(url: song.thumbnailUrl),
                title: Text(song.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => playAndOpen(context, song, queue: songs),
              );
            },
          );
        },
      ),
    );
  }
}
