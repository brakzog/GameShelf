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

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'launcher': launcher.name,
        'installPath': installPath,
        'launchTarget': launchTarget,
      };

  factory GameEntry.fromJson(Map<String, Object?> json) {
    final launcherName = json['launcher'] as String?;
    final launcher = LauncherType.values.firstWhere(
      (value) => value.name == launcherName,
      orElse: () => LauncherType.steam,
    );

    return GameEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Jeu inconnu',
      launcher: launcher,
      installPath: json['installPath'] as String?,
      launchTarget: json['launchTarget'] as String?,
    );
  }
}
