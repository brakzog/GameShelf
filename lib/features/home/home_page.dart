import 'package:flutter/material.dart';

import 'package:gameshelf/app/app_services.dart';
import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/library/widgets/game_cover.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenLibrary,
    required this.onOpenFavorites,
  });

  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenFavorites;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GameEntry> _games = const <GameEntry>[];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final games = await AppServices.repository.getInstalledGames();

      if (!mounted) {
        return;
      }

      setState(() {
        _games = games;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  List<GameEntry> get _favorites {
    return _games
        .where((game) => game.favorite)
        .take(5)
        .toList(growable: false);
  }

  int _countForLauncher(LauncherType launcher) {
    return _games.where((game) => game.launcher == launcher).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadGames,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  32,
                  28,
                  32,
                  40,
                ),
                sliver: SliverList.list(
                  children: <Widget>[
                    _buildHeader(context),
                    const SizedBox(height: 32),
                    if (_loading)
                      const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      _buildError(context)
                    else ...<Widget>[
                      _buildStatistics(context),
                      const SizedBox(height: 38),
                      _buildFavorites(context),
                      const SizedBox(height: 38),
                      _buildRandomGameCard(context),
                      const SizedBox(height: 38),
                      _buildLibraryPreview(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Bonjour Julien',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'À quoi allons-nous jouer aujourd’hui ?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: _loading ? null : _loadGames,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser l’accueil',
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: <Widget>[
        _StatisticCard(
          icon: Icons.sports_esports_rounded,
          value: '${_games.length}',
          label: 'Jeux installés',
        ),
        _StatisticCard(
          icon: Icons.star_rounded,
          value: '${_favorites.length}',
          label: 'Favoris',
        ),
        _StatisticCard(
          icon: Icons.cloud_outlined,
          value: '${_countForLauncher(LauncherType.steam)}',
          label: 'Steam',
        ),
        _StatisticCard(
          icon: Icons.storefront_outlined,
          value: '${_countForLauncher(LauncherType.gog)}',
          label: 'GOG',
        ),
        _StatisticCard(
          icon: Icons.rocket_launch_outlined,
          value: '${_countForLauncher(LauncherType.epic)}',
          label: 'Epic',
        ),
      ],
    );
  }

  Widget _buildFavorites(BuildContext context) {
    return _Section(
      title: 'Favoris',
      subtitle: _favorites.isEmpty
          ? 'Ajoute quelques jeux à tes favoris.'
          : 'Tes jeux préférés, toujours accessibles.',
      actionLabel: 'Tout afficher',
      onActionPressed: widget.onOpenFavorites,
      child: _favorites.isEmpty
          ? _EmptyFavorites(
              onOpenLibrary: widget.onOpenLibrary,
            )
          : SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 18),
                itemBuilder: (context, index) {
                  return _FavoriteGameCard(
                    game: _favorites[index],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildRandomGameCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.casino_rounded,
              size: 38,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Je ne sais pas à quoi jouer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Laisse GameShelf choisir un jeu installé pour toi.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          FilledButton.icon(
            onPressed: _games.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Le choix aléatoire arrive dans la prochaine étape 😄',
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.casino_rounded),
            label: const Text('Choisir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryPreview(BuildContext context) {
    final previewGames = _games.take(6).toList(growable: false);

    return _Section(
      title: 'Bibliothèque',
      subtitle: '${_games.length} jeux réunis dans GameShelf.',
      actionLabel: 'Ouvrir',
      onActionPressed: widget.onOpenLibrary,
      child: previewGames.isEmpty
          ? const SizedBox(
              height: 120,
              child: Center(
                child: Text('Aucun jeu installé détecté.'),
              ),
            )
          : Wrap(
              spacing: 18,
              runSpacing: 18,
              children: previewGames
                  .map(
                    (game) => _LibraryPreviewCard(
                      game: game,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            'Impossible de charger la bibliothèque.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '$_error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadGames,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onActionPressed,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onActionPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(actionLabel),
            ),
          ],
        ),
        const SizedBox(height: 18),
        child,
      ],
    );
  }
}

class _FavoriteGameCard extends StatelessWidget {
  const _FavoriteGameCard({
    required this.game,
  });

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GameCover(
            game: game,
            width: 145,
            height: 200,
            borderRadius: 16,
          ),
          const SizedBox(height: 10),
          Text(
            game.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            game.launcherLabel,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryPreviewCard extends StatelessWidget {
  const _LibraryPreviewCard({
    required this.game,
  });

  final GameEntry game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          GameCover(
            game: game,
            width: 62,
            height: 86,
            borderRadius: 10,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  game.launcherLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({
    required this.onOpenLibrary,
  });

  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.star_border_rounded,
            size: 42,
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Text(
              'Tu n’as encore ajouté aucun jeu aux favoris.',
            ),
          ),
          OutlinedButton(
            onPressed: onOpenLibrary,
            child: const Text('Voir la bibliothèque'),
          ),
        ],
      ),
    );
  }
}
