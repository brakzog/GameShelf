import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/providers/game_provider.dart';
import 'package:gameshelf/features/scanning/launcher_scanner.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';

abstract class BaseGameProvider implements GameProvider {
  const BaseGameProvider({
    required LauncherScanner scanner,
    required GameLauncher launcher,
    required CoverService coverService,
  })  : _scanner = scanner,
        _launcher = launcher,
        _coverService = coverService;

  final LauncherScanner _scanner;
  final GameLauncher _launcher;
  final CoverService _coverService;

  @override
  String get name => _scanner.name;

  @override
  Future<List<GameEntry>> scan() {
    return _scanner.scan();
  }

  @override
  Future<void> launch(GameEntry game) {
    _validateLauncher(game);

    return _launcher.launch(game);
  }

  @override
  Future<String?> resolveCover(GameEntry game) {
    _validateLauncher(game);

    return _coverService.resolveCover(game);
  }

  void _validateLauncher(GameEntry game) {
    if (game.launcher != launcherType) {
      throw ArgumentError(
        'Le provider ${launcherType.name} ne peut pas gérer '
        'un jeu ${game.launcher.name}.',
      );
    }
  }
}
