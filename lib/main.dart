import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const GameShelfApp());
}

class GameShelfApp extends StatelessWidget {
  const GameShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameShelf',
      theme: ThemeData.dark(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

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

  String get launcherLabel => switch (launcher) {
        LauncherType.steam => 'Steam',
        LauncherType.gog => 'GOG',
      };
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<GameEntry> _allGames = [];
  bool _loading = false;
  String _status = 'Prêt';

  List<GameEntry> get _filteredGames {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allGames;
    return _allGames
        .where((game) => game.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _scanGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanGames() async {
    setState(() {
      _loading = true;
      _status = 'Scan Steam + GOG...';
    });

    final games = <GameEntry>[];
    final errors = <String>[];

    try {
      games.addAll(await SteamScanner.scan());
    } catch (error) {
      errors.add('Steam: $error');
    }

    try {
      games.addAll(await GogScanner.scan());
    } catch (error) {
      errors.add('GOG: $error');
    }

    games.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    setState(() {
      _allGames = games;
      _loading = false;
      _status = errors.isEmpty
          ? '${games.length} jeu(x) détecté(s)'
          : '${games.length} jeu(x) détecté(s), erreurs: ${errors.join(' | ')}';
    });
  }

  Future<void> _launch(GameEntry game) async {
    try {
      if (game.launcher == LauncherType.steam) {
        await Process.start('cmd', ['/c', 'start', '', 'steam://rungameid/${game.id}']);
        return;
      }

      if (game.launcher == LauncherType.gog && game.launchTarget != null) {
        await Process.start(game.launchTarget!, [], workingDirectory: game.installPath);
        return;
      }

      throw Exception('Aucune cible de lancement trouvée');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lancer ${game.title}: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final games = _filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GameShelf 0.1'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _scanGames,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rescanner',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                hintText: 'Rechercher un jeu...',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_loading) const SizedBox(width: 12),
                Expanded(child: Text(_status, maxLines: 2, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: games.isEmpty && !_loading
                ? const Center(child: Text('Aucun jeu trouvé'))
                : ListView.separated(
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(game.launcherLabel[0])),
                        title: Text(game.title),
                        subtitle: Text('${game.launcherLabel}${game.installPath == null ? '' : ' • ${game.installPath}'}'),
                        trailing: FilledButton.icon(
                          onPressed: () => _launch(game),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Jouer'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SteamScanner {
  static Future<List<GameEntry>> scan() async {
    if (!Platform.isWindows) return [];

    final steamRoot = await _findSteamRoot();
    if (steamRoot == null) return [];

    final libraryFile = File('$steamRoot\\steamapps\\libraryfolders.vdf');
    final libraryRoots = <String>{steamRoot};

    if (await libraryFile.exists()) {
      final content = await libraryFile.readAsString();
      final pathRegex = RegExp(r'"path"\s+"([^"]+)"');
      for (final match in pathRegex.allMatches(content)) {
        final path = match.group(1)?.replaceAll('\\\\', '\\');
        if (path != null && path.trim().isNotEmpty) {
          libraryRoots.add(path);
        }
      }
    }

    final games = <GameEntry>[];
    for (final root in libraryRoots) {
      final steamApps = Directory('$root\\steamapps');
      if (!await steamApps.exists()) continue;

      await for (final entity in steamApps.list(followLinks: false)) {
        if (entity is! File) continue;
        final filename = entity.uri.pathSegments.last;
        if (!filename.startsWith('appmanifest_') || !filename.endsWith('.acf')) continue;

        final content = await entity.readAsString(errors: utf8.decoder);
        final appId = _readVdfValue(content, 'appid');
        final name = _readVdfValue(content, 'name');
        final installDir = _readVdfValue(content, 'installdir');

        if (appId == null || name == null) continue;
        games.add(GameEntry(
          id: appId,
          title: name,
          launcher: LauncherType.steam,
          installPath: installDir == null ? null : '$root\\steamapps\\common\\$installDir',
          launchTarget: 'steam://rungameid/$appId',
        ));
      }
    }

    return games;
  }

  static Future<String?> _findSteamRoot() async {
    final env = Platform.environment;
    final candidates = <String>[
      if (env['PROGRAMFILES(X86)'] != null) '${env['PROGRAMFILES(X86)']}\\Steam',
      if (env['PROGRAMFILES'] != null) '${env['PROGRAMFILES']}\\Steam',
    ];

    for (final candidate in candidates) {
      if (await Directory(candidate).exists()) return candidate;
    }

    // Fallback registry.
    final result = await _runRegQuery(r'HKCU\Software\Valve\Steam', 'SteamPath');
    if (result != null) return result.replaceAll('/', '\\');
    return null;
  }
}

class GogScanner {
  static Future<List<GameEntry>> scan() async {
    if (!Platform.isWindows) return [];

    final uninstallKeys = [
      r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
      r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    ];

    final games = <GameEntry>[];
    final seen = <String>{};

    for (final key in uninstallKeys) {
      final subKeys = await _runRegListKeys(key);
      for (final subKey in subKeys) {
        final displayName = await _runRegQuery(subKey, 'DisplayName');
        final publisher = await _runRegQuery(subKey, 'Publisher');
        final installLocation = await _runRegQuery(subKey, 'InstallLocation');
        final displayIcon = await _runRegQuery(subKey, 'DisplayIcon');

        final looksLikeGog = (publisher ?? '').toLowerCase().contains('gog') ||
            subKey.toLowerCase().contains('gog.com') ||
            (installLocation ?? '').toLowerCase().contains('gog');

        if (!looksLikeGog || displayName == null) continue;
        if (!seen.add(displayName.toLowerCase())) continue;

        final exe = await _findLaunchExe(installLocation, displayIcon);
        games.add(GameEntry(
          id: subKey,
          title: displayName,
          launcher: LauncherType.gog,
          installPath: installLocation,
          launchTarget: exe,
        ));
      }
    }

    return games;
  }

  static Future<String?> _findLaunchExe(String? installLocation, String? displayIcon) async {
    final iconExe = _cleanExePath(displayIcon);
    if (iconExe != null && await File(iconExe).exists()) return iconExe;

    if (installLocation == null || installLocation.isEmpty) return null;
    final dir = Directory(installLocation);
    if (!await dir.exists()) return null;

    final candidates = <File>[];
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
        final name = entity.uri.pathSegments.last.toLowerCase();
        if (!name.contains('unins') && !name.contains('setup') && !name.contains('redist')) {
          candidates.add(entity);
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.path.length.compareTo(b.path.length));
    return candidates.first.path;
  }

  static String? _cleanExePath(String? value) {
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

String? _readVdfValue(String content, String key) {
  final regex = RegExp('"$key"\\s+"([^\\"]*)"');
  return regex.firstMatch(content)?.group(1);
}

Future<String?> _runRegQuery(String key, String valueName) async {
  try {
    final result = await Process.run('reg', ['query', key, '/v', valueName]);
    if (result.exitCode != 0) return null;
    final output = result.stdout.toString();
    final lines = const LineSplitter().convert(output);
    for (final line in lines) {
      if (!line.contains(valueName)) continue;
      final parts = line.trim().split(RegExp(r'\s{2,}'));
      if (parts.length >= 3) return parts.sublist(2).join(' ').trim();
    }
  } catch (_) {
    return null;
  }
  return null;
}

Future<List<String>> _runRegListKeys(String key) async {
  try {
    final result = await Process.run('reg', ['query', key]);
    if (result.exitCode != 0) return [];
    final output = result.stdout.toString();
    return const LineSplitter()
        .convert(output)
        .map((line) => line.trim())
        .where((line) => line.startsWith('HKEY_'))
        .where((line) => line != key)
        .toList();
  } catch (_) {
    return [];
  }
}
