import 'dart:math';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/history_service.dart';
import '../services/youtube_service.dart';
import '../theme.dart';
import '../widgets/thumb.dart';
import 'player_screen.dart';
import 'song_list_screen.dart';

class _Mood {
  final String label;
  final String query;
  final IconData icon;
  final List<Color> colors;

  const _Mood(this.label, this.query, this.icon, this.colors);
}

const _moods = <_Mood>[
  _Mood('Santai', 'lagu santai', Icons.spa_outlined,
      [Color(0xFF1F8A82), Color(0xFF0C3B39)]),
  _Mood('Perjalanan', 'lagu perjalanan', Icons.directions_car_outlined,
      [Color(0xFFE0603A), Color(0xFF4A1C10)]),
  _Mood('Tidur', 'musik tidur', Icons.nights_stay_outlined,
      [Color(0xFF4A4FB0), Color(0xFF161A3D)]),
  _Mood('Sendu', 'lagu sedih', Icons.water_drop_outlined,
      [Color(0xFF55688C), Color(0xFF1A2232)]),
  _Mood('Semangat', 'lagu semangat', Icons.bolt_outlined,
      [Color(0xFFD9A62B), Color(0xFF5C4A0E)]),
];

const _popularQuery = 'lagu populer indonesia';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  List<Song> _quick = [];
  bool _loadingQuick = true;
  List<Song> _history = [];

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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: kEmber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodRow() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final m = _moods[i];
          return _MoodTile(
            mood: m,
            onTap: () => _openList(m.label, () => YoutubeService.instance.search(m.query)),
          );
        },
      ),
    );
  }

  Widget _topTen() {
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
    final top = _quick.take(10).toList();
    return Column(
      children: [
        for (var i = 0; i < top.length; i++)
          _RankRow(
            rank: i + 1,
            song: top[i],
            onTap: () => playAndOpen(context, top[i], queue: _quick),
          ),
      ],
    );
  }

  Widget _historyRow() {
    if (_history.isEmpty) {
      return Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Lagu yang kamu putar akan muncul di sini',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final song = _history[i];
          return SizedBox(
            width: 130,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => playAndOpen(context, song, queue: _history),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SongThumb(url: song.thumbnailUrl, size: 130, radius: 20),
                  const SizedBox(height: 8),
                  Text(
                    song.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.graphic_eq, color: kEmber, size: 26),
            SizedBox(width: 8),
            Text('contolustic'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat',
            onPressed: () => _openList('Riwayat', HistoryService.instance.loadAll),
          ),
          IconButton(
            icon: const Icon(Icons.local_fire_department_outlined),
            tooltip: 'Populer',
            onPressed: () => _openList(
              'Populer',
              () => YoutubeService.instance.search(_popularQuery),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Acak',
        backgroundColor: kEmber,
        foregroundColor: Colors.black,
        onPressed: (_loadingQuick || _quick.isEmpty) ? null : _shuffleQuick,
        icon: const Icon(Icons.shuffle_rounded),
        label: const Text('Acak', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Text(
              'Selamat ${_greeting()}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          _moodRow(),
          const SizedBox(height: 28),
          _sectionTitle('Top 10 hari ini'),
          _topTen(),
          const SizedBox(height: 28),
          _sectionTitle('Lanjut dengarkan'),
          _historyRow(),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final _Mood mood;
  final VoidCallback onTap;

  const _MoodTile({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: mood.colors,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(mood.icon, color: Colors.white, size: 26),
                  Text(
                    mood.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final Song song;
  final VoidCallback onTap;

  const _RankRow({required this.rank, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: top3 ? kEmber : Colors.white30,
                ),
              ),
            ),
            SongThumb(url: song.thumbnailUrl, size: 52, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
