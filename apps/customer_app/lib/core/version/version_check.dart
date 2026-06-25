/// Returns true when the installed [current] version is strictly below the
/// [minSupported] floor, using dot-separated numeric comparison
/// (major.minor.patch). Build metadata and pre-release suffixes are ignored
/// ("1.2.0+5" / "1.2.0-rc1" → "1.2.0"). Missing segments count as 0.
bool isUpdateRequired(String current, String minSupported) {
  final c = _parse(current);
  final m = _parse(minSupported);
  for (var i = 0; i < 3; i++) {
    if (c[i] < m[i]) return true;
    if (c[i] > m[i]) return false;
  }
  return false;
}

List<int> _parse(String version) {
  final core = version.split('+').first.split('-').first.trim();
  final parts = core.split('.');
  final out = <int>[0, 0, 0];
  for (var i = 0; i < 3 && i < parts.length; i++) {
    out[i] = int.tryParse(parts[i].trim()) ?? 0;
  }
  return out;
}
