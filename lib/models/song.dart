import 'dart:convert';

class Song {
  final String id; // ID video YouTube
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration? duration;

  /// Terisi jika lagu sudah diunduh untuk offline.
  final String? localPath;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.duration,
    this.localPath,
  });

  bool get isDownloaded => localPath != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnailUrl': thumbnailUrl,
        'durationMs': duration?.inMilliseconds,
        'localPath': localPath,
      };

  factory Song.fromJson(Map<String, dynamic> j) => Song(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        thumbnailUrl: j['thumbnailUrl'] as String,
        duration: j['durationMs'] == null
            ? null
            : Duration(milliseconds: j['durationMs'] as int),
        localPath: j['localPath'] as String?,
      );

  static List<Song> listFromJson(String raw) => (jsonDecode(raw) as List)
      .map((e) => Song.fromJson(e as Map<String, dynamic>))
      .toList();

  static String listToJson(List<Song> songs) =>
      jsonEncode(songs.map((s) => s.toJson()).toList());
}
