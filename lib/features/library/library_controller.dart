import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/domain/repositories/game_repository.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/scanning/game_scanner.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({
    required GameRepository repository,
    required GameScanner scanner,
    required GameLauncher launcher,
    required CoverService coverService,
  })  : _repository = repository,
        _scanner = scanner,
        _launcher = launcher,
        _coverService = coverService;

  final GameRepository _repository;
  final GameScanner _scanner;
  final GameLauncher _launcher;
  final CoverService _coverService;

  int _coversCompleted = 0;
  int _coversTotal = 0;
  bool _loadingCovers = false;

  int get coversCompleted => _coversCompleted;
  int get coversTotal => _coversTotal;
  bool get loadingCovers => _loadingCovers;

  double get coverProgress {
    if (_coversTotal == 0) {
      return 1;
    }

    return _coversCompleted / _coversTotal;
  }

  List<GameEntry> _games = const <GameEntry>[];
  bool _refreshing = false;
  String _status = 'Chargement de la bibliothèque...';

  List<GameEntry> get games => _games;
  bool get refreshing => _refreshing;
  String get status => _status;

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
    if (_refreshing) return;

    _refreshing = true;

    _status = showBlockingStatus || _games.isEmpty
        ? 'Scan Steam + GOG + Epic...'
        : '${_games.length} jeux affichés • '
            'actualisation en arrière-plan...';

    notifyListeners();

    final stopwatch = Stopwatch()..start();
    final result = await _scanner.scanAll();
    stopwatch.stop();

    if (result.games.isNotEmpty || _games.isEmpty) {
      await _repository.replaceInstalledGames(result.games);
      _games = await _repository.getInstalledGames();
    }

    final steamCount =
        _games.where((game) => game.launcher == LauncherType.steam).length;

    final gogCount =
        _games.where((game) => game.launcher == LauncherType.gog).length;

    final epicCount =
        _games.where((game) => game.launcher == LauncherType.epic).length;

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

  Future<void> _loadMissingCovers() async {
    if (_loadingCovers) {
      return;
    }

    final gamesSnapshot = List<GameEntry>.from(_games);

    final gamesToProcess = gamesSnapshot
        .where(
          (game) => game.coverPath == null || game.coverPath!.isEmpty,
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
        final coverPath = await _coverService.resolveCover(game);

        if (coverPath != null) {
          await _repository.setCoverPath(game, coverPath);

          final index = _games.indexWhere(
            (candidate) => candidate.databaseId == game.databaseId,
          );

          if (index != -1) {
            final updatedGames = List<GameEntry>.from(_games);

            updatedGames[index] = updatedGames[index].copyWith(
              coverPath: coverPath,
            );

            _games = List<GameEntry>.unmodifiable(updatedGames);
          }
        }
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

    await _repository.setFavorite(game, favorite);
    _games = await _repository.getInstalledGames();

    notifyListeners();
  }

  Future<void> launch(GameEntry game) {
    return _launcher.launch(game);
  }
}
