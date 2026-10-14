String fmtDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  return d.inHours > 0
      ? '${d.inHours}:${two(m)}:${two(s)}'
      : '${two(m)}:${two(s)}';
}
