import 'package:flutter/material.dart';

import 'package:gameshelf/domain/models/game_entry.dart';

import 'game_cover.dart';
import 'launcher_badge.dart';
import 'gs_play_button.dart';

class GameGridCard extends StatefulWidget {
  const GameGridCard({
    super.key,
    required this.game,
    required this.onLaunch,
    required this.onToggleFavorite,
  });

  final GameEntry game;
  final VoidCallback onLaunch;
  final VoidCallback onToggleFavorite;

  @override
  State<GameGridCard> createState() => _GameGridCardState();
}

class _GameGridCardState extends State<GameGridCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedSlide(
        offset: _hovered ? const Offset(0, -0.015) : Offset.zero,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: _hovered
                  ? <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.42),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: _hovered ? 8 : 1,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onDoubleTap: widget.onLaunch,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          GameCover(
                            game: widget.game,
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 0,
                          ),
                          IgnorePointer(
                            ignoring: !_hovered,
                            child: AnimatedOpacity(
                              opacity: _hovered ? 1 : 0,
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOut,
                              child: ColoredBox(
                                color: Colors.black.withValues(alpha: 0.70),
                                child: Center(
                                  child: GsPlayButton(
                                    onPressed: widget.onLaunch,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: LauncherBadge(
                              launcher: widget.game.launcher,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: colorScheme.surface.withValues(alpha: 0.9),
                              shape: const CircleBorder(),
                              elevation: _hovered ? 4 : 1,
                              child: IconButton(
                                onPressed: widget.onToggleFavorite,
                                icon: Icon(
                                  widget.game.favorite
                                      ? Icons.star
                                      : Icons.star_border,
                                ),
                                color: widget.game.favorite
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                                tooltip: widget.game.favorite
                                    ? 'Retirer des favoris'
                                    : 'Ajouter aux favoris',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.game.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
