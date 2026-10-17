import 'package:flutter/material.dart';

import '../models/song.dart';
import '../screens/player_screen.dart';
import '../services/player_service.dart';
import '../theme.dart';
import 'thumb.dart';

/// Kartu pemutar kecil yang melayang di atas navigasi, dengan garis progres tipis.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PlayerService.instance;

    return ValueListenableBuilder<Song?>(
      valueListenable: service.current,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: kSurfaceHigh,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PlayerScreen(song: song)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                    child: Row(
                      children: [
                        SongThumb(url: song.thumbnailUrl, size: 44, radius: 12),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<bool>(
                          stream: service.player.playingStream,
                          builder: (context, snap) {
                            final playing = snap.data ?? false;
                            return IconButton.filled(
                              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              onPressed: () => playing
                                  ? service.player.pause()
                                  : service.player.play(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<Duration>(
                    stream: service.player.positionStream,
                    builder: (context, snap) {
                      final pos = snap.data?.inMilliseconds ?? 0;
                      final total = service.player.duration?.inMilliseconds ?? 0;
                      final value = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;
                      return LinearProgressIndicator(
                        value: value.toDouble(),
                        minHeight: 2,
                        backgroundColor: Colors.white10,
                        color: kEmber,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
