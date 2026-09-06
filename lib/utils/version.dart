bool isVersionOutdated(String current, String latest) {
  final currentParts = _numericParts(current);
  final latestParts = _numericParts(latest);
  final length = currentParts.length > latestParts.length
      ? currentParts.length
      : latestParts.length;

  for (var index = 0; index < length; index++) {
    final currentPart = index < currentParts.length ? currentParts[index] : 0;
    final latestPart = index < latestParts.length ? latestParts[index] : 0;
    if (currentPart != latestPart) return currentPart < latestPart;
  }

  return false;
}

List<int> _numericParts(String version) {
  final core = version.split(RegExp(r'[+-]')).first;
  return core.split('.').map((part) => int.tryParse(part) ?? 0).toList();
}
