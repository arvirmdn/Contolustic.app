import 'package:flutter/material.dart';

import 'downloads_screen.dart';
import 'playlists_screen.dart';

/// Pustaka: gabungan Playlist dan Unduhan dalam satu layar dengan tab.
class PustakaScreen extends StatelessWidget {
  const PustakaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Koleksi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daftar Putar'),
              Tab(text: 'Unduhan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PlaylistsScreen(embedded: true),
            DownloadsScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}
