import 'song.dart';

class Playlist {
  final String id;
  final String name;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.songs = const [],
  });

  Playlist copyWith({String? name, List<Song>? songs}) => Playlist(
        id: id,
        name: name ?? this.name,
        songs: songs ?? this.songs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songs': songs.map((s) => s.toJson()).toList(),
      };

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] as String,
        name: j['name'] as String,
        songs: (j['songs'] as List)
            .map((e) => Song.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
