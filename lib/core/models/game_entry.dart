enum LauncherType { steam, gog }

class GameEntry {
  final String id;
  final String title;
  final LauncherType launcher;
  final String? installPath;
  final String? launchTarget;

  const GameEntry({
    required this.id,
    required this.title,
    required this.launcher,
    this.installPath,
    this.launchTarget,
  });

  String get launcherLabel {
    switch (launcher) {
      case LauncherType.steam:
        return 'Steam';
      case LauncherType.gog:
        return 'GOG';
    }
  }
}
