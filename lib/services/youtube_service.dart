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
    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    return manifest.audioOnly.withHighestBitrate();
  }

  /// Bytes audio, dipakai saat mengunduh.
  Stream<List<int>> openStream(AudioOnlyStreamInfo info) =>
      _yt.videos.streamsClient.get(info);
}
