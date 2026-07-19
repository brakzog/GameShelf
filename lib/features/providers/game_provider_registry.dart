import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/providers/game_provider.dart';

class ProviderScanResult {
  const ProviderScanResult({
    required this.games,
    required this.errors,
  });

  final List<GameEntry> games;
  final List<String> errors;
}

class GameProviderRegistry {
  GameProviderRegistry({
    required Iterable<GameProvider> providers,
  }) : _providers = <LauncherType, GameProvider>{
          for (final provider in providers) provider.launcherType: provider,
        };

  final Map<LauncherType, GameProvider> _providers;

  Iterable<GameProvider> get providers => _providers.values;

  GameProvider providerFor(LauncherType launcherType) {
    final provider = _providers[launcherType];

    if (provider == null) {
      throw StateError(
        'Aucun provider enregistré pour ${launcherType.name}.',
      );
    }

    return provider;
  }

  Future<ProviderScanResult> scanAll() async {
    final games = <GameEntry>[];
    final errors = <String>[];

    for (final provider in providers) {
      try {
        games.addAll(
          await provider.scan(),
        );
      } catch (error) {
        errors.add('${provider.name}: $error');
      }
    }

    games.sort(
      (first, second) =>
          first.title.toLowerCase().compareTo(second.title.toLowerCase()),
    );

    return ProviderScanResult(
      games: List<GameEntry>.unmodifiable(games),
      errors: List<String>.unmodifiable(errors),
    );
  }

  Future<void> launch(GameEntry game) {
    return providerFor(game.launcher).launch(game);
  }

  Future<String?> resolveCover(GameEntry game) {
    return providerFor(game.launcher).resolveCover(game);
  }
}
