import 'dart:io';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/artwork/artwork_resolver.dart';

class GameArtworkService {
  final List<ArtworkResolver> resolvers;

  const GameArtworkService({
    required this.resolvers,
  });

  Future<GameEntry> resolve(GameEntry game) async {
    final currentCover = game.coverPath?.trim();

    if (currentCover != null &&
        currentCover.isNotEmpty &&
        await File(currentCover).exists()) {
      return game;
    }

    for (final resolver in resolvers) {
      final coverPath = await resolver.resolve(game);

      if (coverPath != null && coverPath.isNotEmpty) {
        return game.copyWith(
          coverPath: coverPath,
        );
      }
    }

    return game;
  }

  Future<List<GameEntry>> resolveAll(
    Iterable<GameEntry> games,
  ) async {
    final resolvedGames = <GameEntry>[];

    for (final game in games) {
      resolvedGames.add(
        await resolve(game),
      );
    }

    return resolvedGames;
  }
}
