import 'package:flutter/material.dart';

import 'package:gameshelf/app/app_services.dart';
import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/library/library_controller.dart';
import 'package:gameshelf/features/library/widgets/game_grid_card.dart';
import 'package:gameshelf/features/library/widgets/game_list_card.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    this.controller,
    this.favoritesOnly = false,
  });

  final LibraryController? controller;
  final bool favoritesOnly;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  late final LibraryController _controller;
  late final bool _ownsController;

  bool _gridView = false;

  @override
  void initState() {
    super.initState();

    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppServices.createLibraryController();

    _controller.addListener(_onControllerChanged);

    if (_ownsController) {
      _controller.initialize();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);

    if (_ownsController) {
      _controller.dispose();
    }

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

    Iterable<GameEntry> games = _controller.games;

    if (widget.favoritesOnly) {
      games = games.where((game) => game.favorite);
    }

    if (query.isNotEmpty) {
      games = games.where((game) {
        return game.title.toLowerCase().contains(query) ||
            game.launcherLabel.toLowerCase().contains(query);
      });
    }

    return games.toList(growable: false);
  }

  Future<void> _launch(GameEntry game) async {
    try {
      await _controller.launch(game);
    } catch (error) {
      if (!mounted) {
        return;
      }

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
    if (widget.favoritesOnly) {
      return CustomScrollView(
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: _LibrarySectionHeader(
              icon: Icons.star_rounded,
              title: 'Jeux favoris',
            ),
          ),
          _buildGameSliverGrid(games),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      );
    }

    return _buildGridSections(games);
  }

  Widget _buildGridSections(List<GameEntry> games) {
    final favorites =
        games.where((game) => game.favorite).toList(growable: false);

    final otherGames =
        games.where((game) => !game.favorite).toList(growable: false);

    return CustomScrollView(
      slivers: <Widget>[
        if (favorites.isNotEmpty) ...<Widget>[
          const SliverToBoxAdapter(
            child: _LibrarySectionHeader(
              icon: Icons.star_rounded,
              title: 'Favoris',
            ),
          ),
          _buildGameSliverGrid(favorites),
          const SliverToBoxAdapter(
            child: SizedBox(height: 12),
          ),
        ],
        SliverToBoxAdapter(
          child: _LibrarySectionHeader(
            icon: Icons.library_books_rounded,
            title: favorites.isEmpty ? 'Bibliothèque' : 'Toute la bibliothèque',
          ),
        ),
        _buildGameSliverGrid(
          favorites.isEmpty ? games : otherGames,
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildGameSliverGrid(List<GameEntry> games) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;

          final columnCount = switch (width) {
            >= 1500 => 7,
            >= 1250 => 6,
            >= 1000 => 5,
            >= 800 => 4,
            >= 600 => 3,
            _ => 2,
          };

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final game = games[index];

                return GameGridCard(
                  game: game,
                  onLaunch: () => _launch(game),
                  onToggleFavorite: () => _controller.toggleFavorite(game),
                );
              },
              childCount: games.length,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = _filteredGames;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.favoritesOnly ? 'Favoris' : 'Bibliothèque',
        ),
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
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                hintText: widget.favoritesOnly
                    ? 'Rechercher dans les favoris...'
                    : 'Rechercher un jeu ou un launcher...',
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
                    widget.favoritesOnly
                        ? '${games.length} jeu${games.length > 1 ? 'x' : ''} '
                            'favori${games.length > 1 ? 's' : ''}'
                        : _controller.status,
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
                ? _EmptyLibraryState(
                    favoritesOnly: widget.favoritesOnly,
                    hasSearch: _searchController.text.trim().isNotEmpty,
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

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({
    required this.favoritesOnly,
    required this.hasSearch,
  });

  final bool favoritesOnly;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String title;
    final String description;

    if (hasSearch) {
      icon = Icons.search_off_rounded;
      title = 'Aucun résultat';
      description = 'Aucun jeu ne correspond à cette recherche.';
    } else if (favoritesOnly) {
      icon = Icons.star_border_rounded;
      title = 'Aucun favori';
      description = 'Ajoute des jeux aux favoris depuis ta bibliothèque.';
    } else {
      icon = Icons.sports_esports_outlined;
      title = 'Aucun jeu trouvé';
      description = 'Lance un nouveau scan pour rechercher les jeux installés.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 58,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibrarySectionHeader extends StatelessWidget {
  const _LibrarySectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 22,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
