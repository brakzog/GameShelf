import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/domain/repositories/game_repository.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/scanning/game_scanner.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({
    required GameRepository repository,
    required GameScanner scanner,
    required GameLauncher launcher,
  })  : _repository = repository,
        _scanner = scanner,
        _launcher = launcher;

  final GameRepository _repository;
  final GameScanner _scanner;
  final GameLauncher _launcher;

  List<GameEntry> _games = const <GameEntry>[];
  bool _refreshing = false;
  String _status = 'Chargement de la bibliothèque...';

  List<GameEntry> get games => _games;
  bool get refreshing => _refreshing;
  String get status => _status;

  Future<void> initialize() async {
    _games = await _repository.getInstalledGames();
    _status = _games.isEmpty
        ? 'Premier scan Steam + GOG...'
        : '${_games.length} jeux chargés depuis SQLite • actualisation en arrière-plan...';
    notifyListeners();

    unawaited(refresh(showBlockingStatus: _games.isEmpty));
  }

  Future<void> refresh({bool showBlockingStatus = false}) async {
    if (_refreshing) return;

    _refreshing = true;
    _status = showBlockingStatus || _games.isEmpty
        ? 'Scan Steam + GOG...'
        : '${_games.length} jeux affichés • actualisation en arrière-plan...';
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
    final duration = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    _refreshing = false;
    _status = result.errors.isEmpty
        ? '${_games.length} jeux installés • Steam: $steamCount • GOG: $gogCount • actualisé en ${duration}s'
        : '${_games.length} jeux • ${duration}s • erreurs: ${result.errors.join(' | ')}';
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
