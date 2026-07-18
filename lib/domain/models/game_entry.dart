enum LauncherType { steam, gog, epic }

class GameEntry {
  final String id;
  final String title;
  final LauncherType launcher;
  final String? installPath;
  final String? launchTarget;
  final String? coverPath;
  final bool favorite;
  final DateTime? lastSeenAt;

  const GameEntry({
    required this.id,
    required this.title,
    required this.launcher,
    this.installPath,
    this.launchTarget,
    this.coverPath,
    this.favorite = false,
    this.lastSeenAt,
  });

  String get launcherLabel {
    switch (launcher) {
      case LauncherType.steam:
        return 'Steam';
      case LauncherType.gog:
        return 'GOG';
      case LauncherType.epic:
        return 'Epic Games';
    }
  }

  String get databaseId => '${launcher.name}:$id';

  GameEntry copyWith({
    String? id,
    String? title,
    LauncherType? launcher,
    String? installPath,
    String? launchTarget,
    String? coverPath,
    bool? favorite,
    DateTime? lastSeenAt,
  }) {
    return GameEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      launcher: launcher ?? this.launcher,
      installPath: installPath ?? this.installPath,
      launchTarget: launchTarget ?? this.launchTarget,
      coverPath: coverPath ?? this.coverPath,
      favorite: favorite ?? this.favorite,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, Object?> toDatabaseMap() => <String, Object?>{
        'database_id': databaseId,
        'source_id': id,
        'title': title,
        'launcher': launcher.name,
        'install_path': installPath,
        'launch_target': launchTarget,
        'cover_path': coverPath,
        'favorite': favorite ? 1 : 0,
        'last_seen_at': (lastSeenAt ?? DateTime.now()).toIso8601String(),
      };

  factory GameEntry.fromDatabaseMap(Map<String, Object?> row) {
    final launcherName = row['launcher'] as String?;
    final launcher = LauncherType.values.firstWhere(
      (value) => value.name == launcherName,
      orElse: () => LauncherType.steam,
    );

    return GameEntry(
      id: row['source_id'] as String? ?? '',
      title: row['title'] as String? ?? 'Jeu inconnu',
      launcher: launcher,
      installPath: row['install_path'] as String?,
      launchTarget: row['launch_target'] as String?,
      coverPath: row['cover_path'] as String?,
      favorite: (row['favorite'] as int? ?? 0) == 1,
      lastSeenAt: DateTime.tryParse(row['last_seen_at'] as String? ?? ''),
    );
  }
}
