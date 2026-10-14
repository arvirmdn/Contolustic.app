import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import '../services/download_service.dart';
import '../services/lyrics_service.dart';
import '../services/player_service.dart';
import '../utils/format.dart';
import '../widgets/thumb.dart';

const double _lineHeight = 56;

/// Memutar lagu lalu membuka layar pemutar.
Future<void> playAndOpen(BuildContext context, Song song) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    await PlayerService.instance.play(song);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Gagal memutar: $e')));
    return;
  }
  navigator.push(MaterialPageRoute(builder: (_) => PlayerScreen(song: song)));
}

class PlayerScreen extends StatefulWidget {
  final Song song;
  const PlayerScreen({super.key, required this.song});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _scroll = ScrollController();
  late final Future<Lyrics?> _lyrics;

  double? _dragMs;
  int _lastIndex = -1;
  bool _downloaded = false;
  bool _busy = false;

  AudioPlayer get _player => PlayerService.instance.player;

  @override
  void initState() {
    super.initState();
    _downloaded = widget.song.isDownloaded;
    _lyrics = LyricsService.fetch(
      title: widget.song.title,
      artist: widget.song.artist,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _downloadCurrent() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await DownloadService.instance.download(widget.song);
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
    final song = widget.song;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sedang diputar')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Thumb(url: song.thumbnailUrl, size: 200, radius: 16),
              const SizedBox(height: 16),
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
              const Divider(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 28,
          icon: Icon(_downloaded ? Icons.download_done : Icons.download_outlined),
          onPressed: (_downloaded || _busy) ? null : _downloadCurrent,
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10),
          onPressed: () {
            final p = _player.position - const Duration(seconds: 10);
            _player.seek(p.isNegative ? Duration.zero : p);
          },
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
          iconSize: 32,
          icon: const Icon(Icons.forward_10),
          onPressed: () => _player.seek(_player.position + const Duration(seconds: 10)),
        ),
        const SizedBox(width: 28),
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
                  color: active ? Colors.white : Colors.white54,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
