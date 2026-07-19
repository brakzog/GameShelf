import 'package:gameshelf/domain/models/game_entry.dart';

abstract interface class GameProvider {
  LauncherType get launcherType;

  String get name;

  Future<List<GameEntry>> scan();

  Future<void> launch(GameEntry game);

  Future<String?> resolveCover(GameEntry game);
}
