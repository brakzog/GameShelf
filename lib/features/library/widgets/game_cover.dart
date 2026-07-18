import 'dart:io';

import 'package:flutter/material.dart';

import 'package:gameshelf/domain/models/game_entry.dart';

class GameCover extends StatelessWidget {
  const GameCover({
    super.key,
    required this.game,
    this.width = 80,
    this.height = 120,
    this.borderRadius = 10,
  });

  final GameEntry game;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final coverPath = game.coverPath;

    if (coverPath != null && coverPath.isNotEmpty) {
      final file = File(coverPath);

      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(context),
          ),
        );
      }
    }

    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: colorScheme.primaryContainer,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.sports_esports,
              color: colorScheme.onPrimaryContainer,
              size: 34,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                game.launcherLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
