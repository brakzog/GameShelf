import 'package:flutter/material.dart';

import 'package:gameshelf/domain/models/game_entry.dart';
import '../../app/app_services.dart';
import 'library_controller.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  late final LibraryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppServices.createLibraryController()
      ..addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  List<GameEntry> get _filteredGames {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _controller.games;
    return _controller.games.where((game) {
      return game.title.toLowerCase().contains(query) ||
          game.launcherLabel.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<void> _launch(GameEntry game) async {
    try {
      await _controller.launch(game);
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
        title: const Text('GameShelf 0.5'),
        actions: <Widget>[
          IconButton(
            onPressed: _controller.refreshing ? null : _controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Rescanner',
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
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
              children: <Widget>[
                if (_controller.refreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_controller.refreshing) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _controller.status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: games.isEmpty && !_controller.refreshing
                ? const Center(child: Text('Aucun jeu trouvé'))
                : ListView.separated(
                    itemCount: games.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      return ListTile(
                        leading:
                            CircleAvatar(child: Text(game.launcherLabel[0])),
                        title: Text(game.title),
                        subtitle: Text(
                          '${game.launcherLabel}${game.installPath == null ? '' : ' • ${game.installPath}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              onPressed: () => _controller.toggleFavorite(game),
                              icon: Icon(
                                game.favorite ? Icons.star : Icons.star_border,
                              ),
                              tooltip: game.favorite
                                  ? 'Retirer des favoris'
                                  : 'Ajouter aux favoris',
                            ),
                            FilledButton.icon(
                              onPressed: () => _launch(game),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Jouer'),
                            ),
                          ],
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
