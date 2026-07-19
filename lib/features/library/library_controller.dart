import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/domain/repositories/game_repository.dart';
import 'package:gameshelf/features/providers/game_provider_registry.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({
    required GameRepository repository,
    required GameProviderRegistry providerRegistry,
  })  : _repository = repository,
        _providerRegistry = providerRegistry;

  final GameRepository _repository;
  final GameProviderRegistry _providerRegistry;

  int _coversCompleted = 0;
  int _coversTotal = 0;
  bool _loadingCovers = false;

  List<GameEntry> _games = const <GameEntry>[];
  bool _refreshing = false;
  String _status = 'Chargement de la bibliothèque...';

  int get coversCompleted => _coversCompleted;
  int get coversTotal => _coversTotal;
  bool get loadingCovers => _loadingCovers;

  List<GameEntry> get games => _games;
  bool get refreshing => _refreshing;
  String get status => _status;

  double get coverProgress {
    if (_coversTotal == 0) {
      return 1;
    }

    return _coversCompleted / _coversTotal;
  }

  Future<void> initialize() async {
    _games = await _repository.getInstalledGames();

    _status = _games.isEmpty
        ? 'Premier scan Steam + GOG + Epic...'
        : '${_games.length} jeux chargés depuis SQLite • '
            'actualisation en arrière-plan...';

    notifyListeners();

    if (_games.isNotEmpty) {
      unawaited(_loadMissingCovers());
    }

    unawaited(
      refresh(
        showBlockingStatus: _games.isEmpty,
      ),
    );
  }

  Future<void> refresh({
    bool showBlockingStatus = false,
  }) async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    _status = showBlockingStatus || _games.isEmpty
        ? 'Scan Steam + GOG + Epic...'
        : '${_games.length} jeux affichés • '
            'actualisation en arrière-plan...';

    notifyListeners();

    final stopwatch = Stopwatch()..start();

    final result = await _providerRegistry.scanAll();

    stopwatch.stop();

    if (result.games.isNotEmpty || _games.isEmpty) {
      await _repository.replaceInstalledGames(result.games);
      _games = await _repository.getInstalledGames();
    }

    final steamCount = _countGamesFor(LauncherType.steam);
    final gogCount = _countGamesFor(LauncherType.gog);
    final epicCount = _countGamesFor(LauncherType.epic);

    final duration = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    _refreshing = false;

    _status = result.errors.isEmpty
        ? '${_games.length} jeux installés • '
            'Steam: $steamCount • '
            'GOG: $gogCount • '
            'Epic: $epicCount • '
            'actualisé en ${duration}s'
        : '${_games.length} jeux • '
            '${duration}s • '
            'erreurs: ${result.errors.join(' | ')}';

    notifyListeners();

    unawaited(_loadMissingCovers());
  }

  int _countGamesFor(LauncherType launcherType) {
    return _games.where((game) => game.launcher == launcherType).length;
  }

  Future<void> _loadMissingCovers() async {
    if (_loadingCovers) {
      return;
    }

    final gamesToProcess = _games
        .where(
          (game) => game.coverPath == null || game.coverPath!.trim().isEmpty,
        )
        .toList(growable: false);

    if (gamesToProcess.isEmpty) {
      _coversCompleted = 0;
      _coversTotal = 0;
      _loadingCovers = false;
      notifyListeners();
      return;
    }

    _loadingCovers = true;
    _coversCompleted = 0;
    _coversTotal = gamesToProcess.length;

    notifyListeners();

    for (final game in gamesToProcess) {
      try {
        final coverPath = await _providerRegistry.resolveCover(game);

        if (coverPath == null || coverPath.isEmpty) {
          continue;
        }

        await _repository.setCoverPath(
          game,
          coverPath,
        );

        final index = _games.indexWhere(
          (candidate) => candidate.databaseId == game.databaseId,
        );

        if (index == -1) {
          continue;
        }

        final updatedGames = List<GameEntry>.from(_games);

        updatedGames[index] = updatedGames[index].copyWith(
          coverPath: coverPath,
        );

        _games = List<GameEntry>.unmodifiable(
          updatedGames,
        );
      } finally {
        _coversCompleted++;
        notifyListeners();
      }
    }

    _loadingCovers = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(GameEntry game) async {
    final favorite = !game.favorite;

    await _repository.setFavorite(
      game,
      favorite,
    );

    _games = await _repository.getInstalledGames();

    notifyListeners();
  }

  Future<void> launch(GameEntry game) {
    return _providerRegistry.launch(game);
  }
}
