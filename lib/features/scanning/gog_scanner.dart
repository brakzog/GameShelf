import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import '../../core/utils/registry.dart';
import 'gog/gog_launcher_locator.dart';
import 'gog/gog_filter.dart';

import 'package:flutter/foundation.dart';

import 'launcher_scanner.dart';

class GogScanner implements LauncherScanner {
  const GogScanner({
    GogLauncherLocator launcherLocator = const GogLauncherLocator(),
    GogFilter filter = const GogFilter(),
  })  : _launcherLocator = launcherLocator,
        _filter = filter;

  final GogLauncherLocator _launcherLocator;
  final GogFilter _filter;
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
        if (!_filter.shouldKeep(displayName, installLocation)) {
          continue;
        }
        if (!seen.add(displayName.toLowerCase())) continue;

        final registryExe = await _findGogRegistryExecutable(
          subKey,
          installLocation,
        );

        final exe = registryExe ??
            await _launcherLocator.findLaunchExe(
              installLocation,
              displayIcon,
            );

        debugPrint('========== GOG ==========');
        debugPrint('Game: $displayName');
        debugPrint('Registry key: $subKey');
        debugPrint('Install location: $installLocation');
        debugPrint('Display icon: $displayIcon');
        debugPrint('Resolved executable: $exe');

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

  Future<String?> _findGogRegistryExecutable(
    String uninstallSubKey,
    String? installLocation,
  ) async {
    final keyName =
        uninstallSubKey.split(r'\').last.replaceFirst(RegExp(r'_is\d+$'), '');

    if (keyName.isEmpty) {
      return null;
    }

    final gogKeys = <String>[
      r'HKLM\SOFTWARE\WOW6432Node\GOG.com\Games\' + keyName,
      r'HKLM\SOFTWARE\GOG.com\Games\' + keyName,
      r'HKCU\SOFTWARE\GOG.com\Games\' + keyName,
    ];

    const executableValues = <String>[
      'exe',
      'gameExe',
      'launchCommand',
      'startMenu',
    ];

    for (final key in gogKeys) {
      for (final valueName in executableValues) {
        final rawValue = await Registry.queryValue(key, valueName);

        final executable = _resolveExecutablePath(
          rawValue,
          installLocation,
        );

        if (executable != null && await File(executable).exists()) {
          return executable;
        }
      }
    }

    return null;
  }

  String? _resolveExecutablePath(
    String? rawValue,
    String? installLocation,
  ) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    var cleaned = rawValue.trim();

    if (cleaned.startsWith('"')) {
      final closingQuote = cleaned.indexOf('"', 1);

      if (closingQuote > 1) {
        cleaned = cleaned.substring(1, closingQuote);
      }
    }

    final exeIndex = cleaned.toLowerCase().indexOf('.exe');

    if (exeIndex < 0) {
      return null;
    }

    cleaned = cleaned.substring(0, exeIndex + 4);

    if (File(cleaned).isAbsolute) {
      return cleaned;
    }

    if (installLocation == null || installLocation.trim().isEmpty) {
      return null;
    }

    return File(
      '${installLocation.replaceAll(RegExp(r'[\\/]+$'), '')}'
      '${Platform.pathSeparator}'
      '$cleaned',
    ).path;
  }
}
