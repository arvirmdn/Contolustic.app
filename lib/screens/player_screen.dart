import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/download_service.dart';
import '../services/lyrics_service.dart';
import '../services/player_service.dart';
import '../utils/format.dart';
import '../widgets/add_to_playlist.dart';
import '../theme.dart';
import '../widgets/thumb.dart';

const double _lineHeight = 56;

/// Memutar lagu (atau antrean) lalu membuka layar pemutar.
Future<void> playAndOpen(
  BuildContext context,
  Song song, {
  List<Song>? queue,
  bool shuffle = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final list = queue ?? [song];
  final start = list.indexWhere((s) => s.id == song.id);
  try {
    await PlayerService.instance.playQueue(
      list,
      startIndex: start < 0 ? 0 : start,
      shuffleOn: shuffle,
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Gagal memutar: $e')));
    return;
  }
  final now = PlayerService.instance.current.value ?? song;
  navigator.push(MaterialPageRoute(builder: (_) => PlayerScreen(song: now)));
}

class PlayerScreen extends StatefulWidget {
  final Song song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _scroll = ScrollController();

  late Song _song;
  late Future<Lyrics?> _lyrics;
  double? _dragMs;
  int _lastIndex = -1;
  bool _downloaded = false;
  bool _busy = false;

  AudioPlayer get _player => PlayerService.instance.player;

  @override
  void initState() {
    super.initState();
    _song = PlayerService.instance.current.value ?? widget.song;
    _loadSong();
    PlayerService.instance.current.addListener(_onSongChanged);
  }

  @override
  void dispose() {
    PlayerService.instance.current.removeListener(_onSongChanged);
    _scroll.dispose();
    super.dispose();
  }

  /// Dipanggil saat lagu berganti (berikutnya, sebelumnya, atau otomatis).
  void _onSongChanged() {
    final now = PlayerService.instance.current.value;
    if (!mounted || now == null || now.id == _song.id) return;
    setState(() {
      _song = now;
      _loadSong();
    });
  }

  void _loadSong() {
    _downloaded = _song.isDownloaded;
    _lastIndex = -1;
    _dragMs = null;
    _lyrics = LyricsService.fetch(title: _song.title, artist: _song.artist);
  }

  Future<void> _downloadCurrent() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await DownloadService.instance.download(_song);
      if (mounted) setState(() => _downloaded = true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Tersimpan untuk diputar offline')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Unduhan gagal: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _activeIndex(List<LyricLine> lines, Duration pos) {
    var idx = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time <= pos) {
        idx = i;
      } else {
        break;
      }
    }
    return idx;
  }

  void _scrollTo(int idx) {
    if (idx < 0 || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final target =
        idx * _lineHeight - pos.viewportDimension / 2 + _lineHeight / 2;
    final clamped = target.clamp(0.0, pos.maxScrollExtent).toDouble();
    _scroll.animateTo(
      clamped,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = _song;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sedang diputar'),
        actions: [
          IconButton(
            icon: Icon(_downloaded ? Icons.download_done : Icons.download_outlined),
            onPressed: (_downloaded || _busy) ? null : _downloadCurrent,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kEmber.withOpacity(0.22), kInk],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: kEmber.withOpacity(0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: SongThumb(url: song.thumbnailUrl, size: 240, radius: 28),
              ),
              const SizedBox(height: 20),
              Text(
                song.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                song.artist,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              _progress(),
              _controls(),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<Lyrics?>(
                  future: _lyrics,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _lyricsView(snap.data);
                  },
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _progress() {
    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snap) {
        final pos = snap.data ?? Duration.zero;
        final totalMs = _player.duration?.inMilliseconds.toDouble() ?? 0;
        final maxMs = totalMs > 0 ? totalMs : 1.0;
        final value = (_dragMs ?? pos.inMilliseconds.toDouble())
            .clamp(0.0, maxMs)
            .toDouble();

        return Column(
          children: [
            Slider(
              value: value,
              max: maxMs,
              onChanged: totalMs > 0
                  ? (v) => setState(() => _dragMs = v)
                  : null,
              onChangeEnd: (v) {
                _player.seek(Duration(milliseconds: v.toInt()));
                setState(() => _dragMs = null);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(fmtDuration(Duration(milliseconds: value.toInt()))),
                Text(fmtDuration(_player.duration ?? Duration.zero)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _controls() {
    final service = PlayerService.instance;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: service.shuffle,
          builder: (context, on, _) => IconButton(
            iconSize: 26,
            tooltip: 'Acak',
            color: on ? Theme.of(context).colorScheme.primary : null,
            icon: const Icon(Icons.shuffle),
            onPressed: service.toggleShuffle,
          ),
        ),
        IconButton(
          iconSize: 36,
          tooltip: 'Sebelumnya',
          icon: const Icon(Icons.skip_previous),
          onPressed: service.previous,
        ),
        StreamBuilder<bool>(
          stream: _player.playingStream,
          builder: (context, snap) {
            final playing = snap.data ?? false;
            return IconButton.filled(
              iconSize: 40,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () => playing ? _player.pause() : _player.play(),
            );
          },
        ),
        IconButton(
          iconSize: 36,
          tooltip: 'Berikutnya',
          icon: const Icon(Icons.skip_next),
          onPressed: service.next,
        ),
        IconButton(
          iconSize: 26,
          tooltip: 'Tambah ke playlist',
          icon: const Icon(Icons.playlist_add),
          onPressed: () => showAddToPlaylist(context, _song),
        ),
      ],
    );
  }

  Widget _lyricsView(Lyrics? lyrics) {
    if (lyrics == null || lyrics.isEmpty) {
      return const Center(child: Text('Lirik tidak ditemukan'));
    }

    if (lyrics.synced.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          lyrics.plain!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
      );
    }

    return StreamBuilder<Duration>(
      stream: _player.positionStream,
      builder: (context, snap) {
        final idx = _activeIndex(lyrics.synced, snap.data ?? Duration.zero);
        if (idx != _lastIndex) {
          _lastIndex = idx;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(idx));
        }
        return ListView.builder(
          controller: _scroll,
          itemCount: lyrics.synced.length,
          itemExtent: _lineHeight,
          itemBuilder: (context, i) {
            final active = i == idx;
            return Center(
              child: Text(
                lyrics.synced[i].text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: active ? 20 : 16,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? Theme.of(context).colorScheme.primary : Colors.white54,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
