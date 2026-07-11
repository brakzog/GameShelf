import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/game_entry.dart';
import '../../core/services/library_cache.dart';
import '../scanning/game_scanner.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<GameEntry> _allGames = [];
  bool _loading = false;
  String _status = 'Chargement de la bibliothèque...';

  List<GameEntry> get _filteredGames {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allGames;
    return _allGames.where((game) {
      return game.title.toLowerCase().contains(query) ||
          game.launcherLabel.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final cachedGames = await LibraryCache.load();
    if (!mounted) return;

    setState(() {
      _allGames = cachedGames;
      _status = cachedGames.isEmpty
          ? 'Premier scan Steam + GOG...'
          : '${cachedGames.length} jeux chargés depuis le cache • actualisation en arrière-plan...';
    });

    await _scanGames(showBlockingLoader: cachedGames.isEmpty);
  }

  Future<void> _scanGames({bool showBlockingLoader = false}) async {
    if (_loading) return;

    setState(() {
      _loading = true;
      if (showBlockingLoader || _allGames.isEmpty) {
        _status = 'Scan Steam + GOG...';
      } else {
        _status = '${_allGames.length} jeux affichés • actualisation en arrière-plan...';
      }
    });

    final stopwatch = Stopwatch()..start();
    final result = await GameScanner.scanAll();
    stopwatch.stop();

    if (result.games.isNotEmpty || _allGames.isEmpty) {
      await LibraryCache.save(result.games);
    }

    if (!mounted) return;
    setState(() {
      if (result.games.isNotEmpty || _allGames.isEmpty) {
        _allGames = result.games;
      }
      _loading = false;

      final steamCount = _allGames
          .where((game) => game.launcher == LauncherType.steam)
          .length;
      final gogCount = _allGames
          .where((game) => game.launcher == LauncherType.gog)
          .length;
      final duration = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

      _status = result.errors.isEmpty
          ? '${_allGames.length} jeux installés • Steam: $steamCount • GOG: $gogCount • actualisé en ${duration}s'
          : '${_allGames.length} jeux • ${duration}s • erreurs: ${result.errors.join(' | ')}';
    });
  }

  Future<void> _launch(GameEntry game) async {
    try {
      switch (game.launcher) {
        case LauncherType.steam:
          await Process.start('cmd', ['/c', 'start', '', 'steam://rungameid/${game.id}']);
          return;
        case LauncherType.gog:
          if (game.launchTarget == null) break;
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
        title: const Text('GameShelf 0.4'),
        actions: [
          IconButton(
            onPressed: _loading ? null : () => _scanGames(),
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
                hintText: 'Rechercher un jeu ou un launcher...',
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
                Expanded(
                  child: Text(
                    _status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                        subtitle: Text(
                          '${game.launcherLabel}${game.installPath == null ? '' : ' • ${game.installPath}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
