import 'dart:math';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/history_service.dart';
import '../services/youtube_service.dart';
import '../widgets/thumb.dart';
import 'player_screen.dart';
import 'song_list_screen.dart';

/// Label chip dan kata kunci pencariannya.
const _moods = [
  ('Relax', 'lagu santai'),
  ('Commute', 'lagu perjalanan'),
  ('Sleep', 'musik tidur'),
  ('Sad', 'lagu sedih'),
  ('Energize', 'lagu semangat'),
];

const _popularQuery = 'lagu populer indonesia';
const _gap = 8.0;
const _perPage = 9;

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  List<Song> _quick = [];
  bool _loadingQuick = true;
  List<Song> _history = [];
  final _pageCtrl = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    HistoryService.changes.addListener(_reloadHistory);
    _reloadHistory();
    _loadQuick();
  }

  @override
  void dispose() {
    HistoryService.changes.removeListener(_reloadHistory);
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadHistory() async {
    final history = await HistoryService.instance.loadAll();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _loadQuick() async {
    try {
      final results = await YoutubeService.instance.search(_popularQuery);
      if (mounted) setState(() => _quick = results.take(18).toList());
    } catch (_) {
      // Dibiarkan kosong, lalu ditampilkan pesan di layar.
    } finally {
      if (mounted) setState(() => _loadingQuick = false);
    }
  }

  void _openList(String title, Future<List<Song>> Function() loader) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SongListScreen(title: title, loader: loader),
      ),
    );
  }

  void _shuffleQuick() {
    if (_quick.isEmpty) return;
    final start = Random().nextInt(_quick.length);
    playAndOpen(context, _quick[start], queue: _quick, shuffle: true);
  }

  Widget _chips() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, query) = _moods[i];
          return ActionChip(
            label: Text(label),
            onPressed: () => _openList(
              label,
              () => YoutubeService.instance.search(query),
            ),
          );
        },
      ),
    );
  }

  Widget _quickPicks() {
    if (_loadingQuick) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_quick.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Gagal memuat lagu. Coba lagi nanti.')),
      );
    }

    final pages = (_quick.length / _perPage).ceil();
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - 2 * _gap) / 3;
        final pageHeight = cell * 3 + 2 * _gap;

        return Column(
          children: [
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: pages,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, p) {
                  final items = _quick.skip(p * _perPage).take(_perPage).toList();
                  return GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: _gap,
                    crossAxisSpacing: _gap,
                    childAspectRatio: 1,
                    children: [
                      for (final s in items)
                        _QuickTile(
                          song: s,
                          onTap: () => playAndOpen(context, s, queue: _quick),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _historyRow() {
    if (_history.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text('Lagu yang kamu putar akan muncul di sini'),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final song = _history[i];
          return SizedBox(
            width: 140,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => playAndOpen(context, song, queue: _history),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SongThumb(url: song.thumbnailUrl, size: 140, radius: 12),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('contolustic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat',
            onPressed: () => _openList('Riwayat', HistoryService.instance.loadAll),
          ),
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Populer',
            onPressed: () => _openList(
              'Populer',
              () => YoutubeService.instance.search(_popularQuery),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Acak',
        onPressed: (_loadingQuick || _quick.isEmpty) ? null : _shuffleQuick,
        child: const Icon(Icons.shuffle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SizedBox(height: 8),
          _chips(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Panggilan cepat',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _quickPicks(),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Lanjut dengarkan',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          _historyRow(),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const _QuickTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: scheme.surfaceContainerHighest);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            song.thumbnailUrl.isEmpty
                ? placeholder
                : Image.network(
                    song.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholder,
                  ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
