import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../models/song.dart';

/// Satu-satunya tempat yang bicara dengan YouTube.
/// Jika YouTube mengubah sistemnya, perbaikan cukup dilakukan di sini.
class YoutubeService {
  YoutubeService._();
  static final YoutubeService instance = YoutubeService._();

  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Song>> search(String query) async {
    final results = await _yt.search.search(query);
    return results
        .map((v) => Song(
              id: v.id.value,
              title: v.title,
              artist: v.author,
              thumbnailUrl: v.thumbnails.mediumResUrl,
              duration: v.duration,
            ))
        .toList();
  }

  /// Stream audio dengan bitrate tertinggi untuk sebuah video.
  Future<AudioOnlyStreamInfo> getBestAudio(String videoId) async {
    final candidates = await getAudioCandidates(videoId);
    return candidates.first;
  }

  /// Beberapa kandidat stream audio, diurutkan dari bitrate tertinggi.
  /// Dipakai sebagai cadangan kalau URL pertama ditolak pemutar.
  Future<List<AudioOnlyStreamInfo>> getAudioCandidates(String videoId) async {
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final best = manifest.audioOnly.withHighestBitrate();
    final others = manifest.audioOnly.where((s) => s.url != best.url).toList()
      ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
    return [best, ...others.take(3)];
  }

  /// Bytes audio, dipakai saat mengunduh.
  Stream<List<int>> openStream(AudioOnlyStreamInfo info) =>
      _yt.videos.streamsClient.get(info);
}
