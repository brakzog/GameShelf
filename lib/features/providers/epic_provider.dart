import 'package:gameshelf/domain/models/game_entry.dart';
import 'package:gameshelf/features/launcher/game_launcher.dart';
import 'package:gameshelf/features/providers/base_game_provider.dart';
import 'package:gameshelf/features/scanning/epic_scanner.dart';
import 'package:gameshelf/infrastructure/covers/cover_service.dart';

class EpicProvider extends BaseGameProvider {
  const EpicProvider({
    EpicScanner scanner = const EpicScanner(),
    required GameLauncher launcher,
    required CoverService coverService,
  }) : super(
          scanner: scanner,
          launcher: launcher,
          coverService: coverService,
        );

  @override
  LauncherType get launcherType => LauncherType.epic;
}
