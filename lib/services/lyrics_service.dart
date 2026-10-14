import 'dart:convert';

import 'package:http/http.dart' as http;

class LyricLine {
  final Duration time;
  final String text;
  const LyricLine(this.time, this.text);
}

class Lyrics {
  /// Lirik dengan waktu (LRC). Kosong jika hanya ada teks biasa.
  final List<LyricLine> synced;

  /// Teks lirik biasa tanpa waktu.
  final String? plain;

  const Lyrics({this.synced = const [], this.plain});

  bool get isEmpty =>
      synced.isEmpty && (plain == null || plain!.trim().isEmpty);
}

/// Mengambil lirik dari lrclib.net (gratis, tanpa API key).
class LyricsService {
  static Future<Lyrics?> fetch({
    required String title,
    required String artist,
  }) async {
    final query = _clean('$artist $title');
    if (query.isEmpty) return null;

    try {
      final uri = Uri.https('lrclib.net', '/api/search', {'q': query});
      final res = await http
          .get(uri, headers: {'User-Agent': 'Metrolist/0.1 (Flutter)'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final list = jsonDecode(res.body) as List<dynamic>;
      if (list.isEmpty) return null;

      final items = list.cast<Map<String, dynamic>>();
      final best = items.firstWhere(
        (e) => (e['syncedLyrics'] as String?)?.isNotEmpty ?? false,
        orElse: () => items.first,
      );

      final synced = best['syncedLyrics'] as String?;
      final plain = best['plainLyrics'] as String?;
      return Lyrics(
        synced: synced == null ? const [] : parseLrc(synced),
        plain: plain,
      );
    } catch (_) {
      return null;
    }
  }

  /// Membuang "(Official Video)", "[HD]", dll dari judul YouTube.
  static String _clean(String s) => s
      .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
      .replaceAll(
        RegExp(r'official|music video|video|lyrics?|audio|hd|4k|- topic',
            caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<LyricLine> parseLrc(String lrc) {
    final re = RegExp(r'^\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\](.*)$');
    final out = <LyricLine>[];
    for (final raw in lrc.split('\n')) {
      final m = re.firstMatch(raw.trim());
      if (m == null) continue;
      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      final ms = int.parse((m.group(3) ?? '0').padRight(3, '0'));
      out.add(LyricLine(
        Duration(minutes: minutes, seconds: seconds, milliseconds: ms),
        m.group(4)!.trim(),
      ));
    }
    return out;
  }
}
