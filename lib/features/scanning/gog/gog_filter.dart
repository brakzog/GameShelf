class GogFilter {
  const GogFilter();

  bool shouldKeep(String displayName, String? installLocation) {
    return !_isLauncherEntry(displayName, installLocation);
  }

  bool _isLauncherEntry(String displayName, String? installLocation) {
    final name = displayName.toLowerCase().trim();
    final path = (installLocation ?? '').toLowerCase();

    return name == 'gog galaxy' ||
        name.startsWith('gog galaxy ') ||
        path.endsWith('\\gog galaxy') ||
        path.endsWith('\\gog galaxy\\');
  }
}
