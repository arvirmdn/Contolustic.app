import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import '../services/playlist_service.dart';

/// Menampilkan daftar playlist untuk menambahkan [song].
Future<void> showAddToPlaylist(BuildContext context, Song song) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _AddToPlaylistSheet(song: song),
  );
}

/// Dialog kecil untuk mengisi nama playlist. Mengembalikan null jika batal.
Future<String?> askPlaylistName(BuildContext context, {String initial = ''}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Nama playlist'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Contoh: Lagu santai'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            Navigator.pop(ctx, text.isEmpty ? null : text);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

class _AddToPlaylistSheet extends StatefulWidget {
  final Song song;
  const _AddToPlaylistSheet({required this.song});

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final lists = await PlaylistService.instance.loadAll();
    if (mounted) setState(() => _playlists = lists);
  }

  Future<void> _addTo(Playlist playlist) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final added = await PlaylistService.instance.addSong(playlist.id, widget.song);
    navigator.pop();
    messenger.showSnackBar(SnackBar(
      content: Text(added
          ? 'Ditambahkan ke ${playlist.name}'
          : 'Lagu sudah ada di ${playlist.name}'),
    ));
  }

  Future<void> _createAndAdd() async {
    final name = await askPlaylistName(context);
    if (name == null) return;
    final playlist = await PlaylistService.instance.create(name);
    await _addTo(playlist);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Playlist baru'),
            onTap: _createAndAdd,
          ),
          if (_playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Belum ada playlist'),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in _playlists)
                  ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(p.name),
                    subtitle: Text('${p.songs.length} lagu'),
                    onTap: () => _addTo(p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
