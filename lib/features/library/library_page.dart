import 'package:flutter/material.dart';

import 'package:gameshelf/domain/models/game_entry.dart';

import '../../app/app_services.dart';
import 'library_controller.dart';
import 'widgets/game_grid_card.dart';
import 'widgets/game_list_card.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  late final LibraryController _controller;

  bool _gridView = false;

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
    if (mounted) {
      setState(() {});
    }
  }

  List<GameEntry> get _filteredGames {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _controller.games;
    }

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
        SnackBar(
          content: Text(
            'Impossible de lancer ${game.title}: $error',
          ),
        ),
      );
    }
  }

  Widget _buildList(List<GameEntry> games) {
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16,
      ),
      itemCount: games.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final game = games[index];

        return GameListCard(
          game: game,
          onLaunch: () => _launch(game),
          onToggleFavorite: () => _controller.toggleFavorite(game),
        );
      },
    );
  }

  Widget _buildGrid(List<GameEntry> games) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final columnCount = switch (width) {
          >= 1500 => 7,
          >= 1250 => 6,
          >= 1000 => 5,
          >= 800 => 4,
          >= 600 => 3,
          _ => 2,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.68,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];

            return GameGridCard(
              game: game,
              onLaunch: () => _launch(game),
              onToggleFavorite: () => _controller.toggleFavorite(game),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GameShelf 0.5'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              setState(() {
                _gridView = !_gridView;
              });
            },
            icon: Icon(
              _gridView ? Icons.view_list : Icons.grid_view,
            ),
            tooltip: _gridView ? 'Vue liste' : 'Vue grille',
          ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
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
          if (_controller.loadingCovers) ...<Widget>[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.image_outlined,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Téléchargement des jaquettes… '
                      '${_controller.coversCompleted} / '
                      '${_controller.coversTotal}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: _controller.coverProgress,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: games.isEmpty && !_controller.refreshing
                ? const Center(
                    child: Text('Aucun jeu trouvé'),
                  )
                : _gridView
                    ? _buildGrid(games)
                    : _buildList(games),
          ),
        ],
      ),
    );
  }
}
