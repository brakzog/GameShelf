import 'package:gameshelf/domain/repositories/game_repository.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/library/library_controller.dart';
import 'package:gameshelf/features/scanning/epic_scanner.dart';
import 'package:gameshelf/features/scanning/game_scanner.dart';
import 'package:gameshelf/features/scanning/gog_scanner.dart';
import 'package:gameshelf/features/scanning/launcher_scanner.dart';
import 'package:gameshelf/features/scanning/steam_scanner.dart';
import 'package:gameshelf/infrastructure/covers/cover_cache.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';
import 'package:gameshelf/infrastructure/covers/providers/steam_cover_provider.dart';

class AppServices {
  AppServices._();

  static final GameRepository repository = const GameRepository();
  static const GameLauncher launcher = GameLauncher();

  static final GameScanner scanner = GameScanner(
    scanners: const <LauncherScanner>[
      SteamScanner(),
      GogScanner(),
      EpicScanner(),
    ],
  );

  static final CoverService coverService = CoverService(
    cache: const CoverCache(),
    providers: const [
      SteamCoverProvider(),
    ],
  );

  static LibraryController createLibraryController() {
    return LibraryController(
      repository: repository,
      scanner: scanner,
      launcher: launcher,
      coverService: coverService,
    );
  }
}
