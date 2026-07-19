import 'package:gameshelf/domain/repositories/game_repository.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/library/library_controller.dart';
import 'package:gameshelf/features/providers/epic_provider.dart';
import 'package:gameshelf/features/providers/game_provider.dart';
import 'package:gameshelf/features/providers/game_provider_registry.dart';
import 'package:gameshelf/features/providers/gog_provider.dart';
import 'package:gameshelf/features/providers/steam_provider.dart';
import 'package:gameshelf/infrastructure/covers/cover_cache.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';
import 'package:gameshelf/infrastructure/covers/providers/steam_cover_provider.dart';

class AppServices {
  AppServices._();

  static final GameRepository repository = const GameRepository();

  static const GameLauncher launcher = GameLauncher();

  static final CoverService coverService = CoverService(
    cache: const CoverCache(),
    providers: const [
      SteamCoverProvider(),
    ],
  );

  static final GameProviderRegistry providerRegistry = GameProviderRegistry(
    providers: <GameProvider>[
      SteamProvider(
        launcher: launcher,
        coverService: coverService,
      ),
      GogProvider(
        launcher: launcher,
        coverService: coverService,
      ),
      EpicProvider(
        launcher: launcher,
        coverService: coverService,
      ),
    ],
  );

  static LibraryController createLibraryController() {
    return LibraryController(
      repository: repository,
      providerRegistry: providerRegistry,
    );
  }
}
