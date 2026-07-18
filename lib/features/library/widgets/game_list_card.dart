import 'package:flutter/material.dart';

import 'package:gameshelf/domain/models/game_entry.dart';

import 'game_cover.dart';

class GameListCard extends StatelessWidget {
  const GameListCard({
    super.key,
    required this.game,
    required this.onLaunch,
    required this.onToggleFavorite,
  });

  final GameEntry game;
  final VoidCallback onLaunch;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onDoubleTap: onLaunch,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              GameCover(game: game),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      game.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.launcherLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(
                  game.favorite ? Icons.star : Icons.star_border,
                ),
                color: game.favorite
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                tooltip: game.favorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                onPressed: onLaunch,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Jouer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
