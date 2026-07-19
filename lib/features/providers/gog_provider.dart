import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/providers/base_game_provider.dart';
import 'package:gameshelf/features/scanning/gog_scanner.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';

class GogProvider extends BaseGameProvider {
  const GogProvider({
    GogScanner scanner = const GogScanner(),
    required GameLauncher launcher,
    required CoverService coverService,
  }) : super(
          scanner: scanner,
          launcher: launcher,
          coverService: coverService,
        );

  @override
  LauncherType get launcherType => LauncherType.gog;
}
