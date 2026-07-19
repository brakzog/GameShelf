import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/providers/base_game_provider.dart';
import 'package:gameshelf/features/scanning/steam_scanner.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';

class SteamProvider extends BaseGameProvider {
  const SteamProvider({
    SteamScanner scanner = const SteamScanner(),
    required GameLauncher launcher,
    required CoverService coverService,
  }) : super(
          scanner: scanner,
          launcher: launcher,
          coverService: coverService,
        );

  @override
  LauncherType get launcherType => LauncherType.steam;
}
