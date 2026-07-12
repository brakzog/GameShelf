import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import '../../core/utils/registry.dart';

import 'launcher_scanner.dart';

class GogScanner implements LauncherScanner {
  const GogScanner();

  @override
  String get name => 'GOG';

  @override
  Future<List<GameEntry>> scan() async {
    if (!Platform.isWindows) return [];

    final uninstallKeys = <String>[
      r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    ];

    final games = <GameEntry>[];
    final seen = <String>{};

    for (final key in uninstallKeys) {
      final subKeys = await Registry.listKeys(key);
      for (final subKey in subKeys) {
        final displayName = await Registry.queryValue(subKey, 'DisplayName');
        final publisher = await Registry.queryValue(subKey, 'Publisher');
        final installLocation =
            await Registry.queryValue(subKey, 'InstallLocation');
        final displayIcon = await Registry.queryValue(subKey, 'DisplayIcon');

        final looksLikeGog = (publisher ?? '').toLowerCase().contains('gog') ||
            subKey.toLowerCase().contains('gog.com') ||
            (installLocation ?? '').toLowerCase().contains('gog');

        if (!looksLikeGog || displayName == null) continue;
        if (_isLauncherEntry(displayName, installLocation)) continue;
        if (!seen.add(displayName.toLowerCase())) continue;

        final exe = await _findLaunchExe(installLocation, displayIcon);
        games.add(
          GameEntry(
            id: subKey,
            title: displayName,
            launcher: LauncherType.gog,
            installPath: installLocation,
            launchTarget: exe,
          ),
        );
      }
    }

    return games;
  }

  bool _isLauncherEntry(String displayName, String? installLocation) {
    final name = displayName.toLowerCase().trim();
    final path = (installLocation ?? '').toLowerCase();

    return name == 'gog galaxy' ||
        name.startsWith('gog galaxy ') ||
        path.endsWith('\\gog galaxy') ||
        path.endsWith('\\gog galaxy\\');
  }

  Future<String?> _findLaunchExe(
      String? installLocation, String? displayIcon) async {
    final iconExe = _cleanExePath(displayIcon);
    if (iconExe != null && await File(iconExe).exists()) return iconExe;

    if (installLocation == null || installLocation.isEmpty) return null;
    final dir = Directory(installLocation);
    if (!await dir.exists()) return null;

    final candidates = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.contains('unins') &&
            !name.contains('setup') &&
            !name.contains('redist')) {
          candidates.add(entity);
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.path.length.compareTo(b.path.length));
    return candidates.first.path;
  }

  String? _cleanExePath(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    var cleaned = value.trim();
    if (cleaned.startsWith('"')) {
      final end = cleaned.indexOf('"', 1);
      if (end > 1) cleaned = cleaned.substring(1, end);
    }
    final exeIndex = cleaned.toLowerCase().indexOf('.exe');
    if (exeIndex >= 0) cleaned = cleaned.substring(0, exeIndex + 4);
    return cleaned;
  }
}
